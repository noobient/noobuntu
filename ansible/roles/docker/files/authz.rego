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

valid_host_path_prefixes = {"/home/", "/proc/", "/tmp/.X11-unix", "/dev/shm"}

# binds
# `docker run -v /:/host-root`

host_bind_paths[trimmed]
{
    # run example:
    # /:/host-root
    #
    # compose example:
    # dockertest_shared_vol:/:rw

    input.Body.HostConfig.Binds[_] = bind

    # find the first / occurence, it is guaranteed to exist
    slashindex := indexof(bind, "/")

    # take the remainder, '/:/host-root' or '/:rw'
    afterslash := substring(bind, slashindex, -1)

    # split into array via ':' delimiter
    parts := split(afterslash, ":")

    # '/' in both cases, magic!
    trimmed := parts[0]

    # TODO why did they trim leading slashes?
    #trim(parts[0], "/", trimmed)
}

valid_host_bind_paths[host_path]
{
    host_bind_paths[host_path]
    startswith(host_path, valid_host_path_prefixes[_])
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
