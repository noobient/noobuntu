# Noobuntu

[Noobuntu](//github.com/noobient/noobuntu) is Enterprise Ubuntu development environment with Active Directory integration. The current release supports Ubuntu 18.04 (Bionic) and 20.04 (Focal).

# Tests

Set up Molecule:

```
sudo apt install -y python3-pip libssl-dev
python3 -m pip install --user ansible ansible-core ansible-lint molecule[docker]
```
