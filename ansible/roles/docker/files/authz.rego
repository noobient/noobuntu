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

# prohibit write access to the host file system which
# would essentially grant root privileges to the user

# binds
# `docker run -v /:/host-root`

host_bind_paths[bind]
{
    input.Body.HostConfig.Binds[_] = bind
}

valid_host_bind_paths[host_path]
{
    host_bind_paths[host_path]
    endswith(host_path, ":ro")
}

valid_bind_mapping_whitelist
{
    invalid_paths = host_bind_paths - valid_host_bind_paths
    count(invalid_paths, 0)
}

# prohibit access to the host file system outside /home
# which would essentially grant root privileges to the user

# bind mounts
# `docker run --mount type=bind,source=/,target=/host-root`

valid_host_path_prefixes = {"home/"}

host_mount_paths[trimmed]
{
    input.Body.HostConfig.Mounts[_] = mount
    trim(mount.Source, "/", trimmed)
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
