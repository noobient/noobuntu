package docker.authz

default allow = false

allow
{
    valid_volume_mapping_whitelist = true
    not unconfined
}

# prohibit disabling the docker-default apparmor profile
# `docker run --security-opt seccomp:unconfined`

unconfined
{
    input.Body.HostConfig.SecurityOpt[_] == "seccomp:unconfined"
}

# prohibit binding the host file system outside home
# which would essentially grant root privileges to the user
# `docker run -v /:/host-root`

valid_host_path_prefixes = {"home/"}

host_volume_paths[trimmed]
{
    input.Body.HostConfig.Binds[_] = bind
    split(bind, ":", parts)
    trim(parts[0], "/", trimmed)
}

valid_host_volume_paths[host_path]
{
    host_volume_paths[host_path]
    startswith(host_path, valid_host_path_prefixes[_])
}

valid_volume_mapping_whitelist
{
    invalid_paths = host_volume_paths - valid_host_volume_paths
    count(invalid_paths, 0)
}

# TODO the same as above, but via bind mount
# `docker run --mount type=bind,source=/,target=/host-root`
# input.Body.HostConfig.Mounts[_].Source?
