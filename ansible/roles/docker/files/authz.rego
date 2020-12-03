package docker.authz

default allow = false

allow
{
    not unconfined
    valid_bind_mapping_whitelist = true
    valid_mount_mapping_whitelist = true
}

# prohibit disabling the docker-default apparmor profile
# `docker run --security-opt seccomp:unconfined`

unconfined
{
    input.Body.HostConfig.SecurityOpt[_] == "seccomp:unconfined"
}

# prohibit access to the host file system outside /home
# which would essentially grant root privileges to the user

valid_host_path_prefixes = {"/home/", "/proc/", "/tmp/.X11-unix", "/dev/shm", "/media/", "/mnt/", "/var/lib/docker/volumes/"}

# binds
# `docker run -v /:/host-root` or `docker run -v $(docker volume create):/host-root`
# possible bind structures:
# /:/host-root[:ro|:rw]
# 9a5d267156747933cb53287069f2c4c26fb6a5d3335e02f14b566e8aad17ddaa:/host-root[:ro|:rw]

host_bind_paths[trimmed]
{
    # run example:
    # /:/host-root
    #
    # compose example:
    # dockertest_shared_vol:/:rw

    input.Body.HostConfig.Binds[_] = bind

    # split into array via ':' delimiter
    parts := split(bind, ":")

    # take full path before first ':'
    trimmed := parts[0]
}

# absolute paths, e.g. /root, compare with prefix allowlist
valid_host_bind_paths[host_path]
{
    host_bind_paths[host_path]
    startswith(host_path, valid_host_path_prefixes[_])
}

# volume id, 64-character alphanumeric
valid_host_bind_paths[host_path]
{
    host_bind_paths[host_path]
    re_match("[a-z0-9]{64}", host_path)
}

valid_bind_mapping_whitelist
{
    invalid_paths = host_bind_paths - valid_host_bind_paths
    count(invalid_paths, 0)
}

# bind mounts
# `docker run --mount type=bind,source=/,target=/host-root`

host_mount_paths[trimmed]
{
    input.Body.HostConfig.Mounts[_] = mount
    trimmed := mount.Source

    # TODO why did they trim leading slashes?
    #trim(mount.Source, "/", trimmed)
}

valid_host_mount_paths[host_path]
{
    host_mount_paths[host_path]
    startswith(host_path, valid_host_path_prefixes[_])
}

valid_mount_mapping_whitelist
{
    invalid_paths = host_mount_paths - valid_host_mount_paths
    count(invalid_paths, 0)
}
