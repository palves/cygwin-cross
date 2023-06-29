#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Author  : Pedro Alves (pedro@palves.net)

groupadd $LOCAL_GROUP -g $LOCAL_GID

useradd -d $HOME -s /bin/bash -M $USER -u $LOCAL_UID -g $LOCAL_GID

if [ $# -gt 0 ]; then
    exec su-exec ${USER} sh -c "cd $LOCAL_CWD && $*"
else
    exec su-exec ${USER} sh -c "cd $LOCAL_CWD && /bin/bash --login"
fi
