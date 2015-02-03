#!/bin/bash
puppet module install zack/r10k
puppet apply configure_r10k.pp
# puppet apply configure_directory_environments.pp
r10k deploy environment -pv
