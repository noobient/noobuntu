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

# bind mounts
# `docker run --mount type=bind,source=/,target=/host-root`

host_mount_paths[mount]
{
    input.Body.HostConfig.Mounts[_] = mount
}

valid_host_mount_paths[host_path]
{
    host_mount_paths[host_path]
    host_path.ReadOnly
}

valid_mount_mapping_whitelist
{
    invalid_paths = host_mount_paths - valid_host_mount_paths
    count(invalid_paths, 0)
}
