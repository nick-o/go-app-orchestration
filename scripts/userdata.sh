#!/usr/bin/env bash

hn=%s
hostname $hn
echo "127.0.0.1 $hn" >> /etc/hosts
echo "$hn" > /etc/hostname
