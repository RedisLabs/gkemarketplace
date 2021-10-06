#!/usr/bin/env bash
mpdev verify --deployer=gcr.io/proven-reality-226706/redislabs/deployer:6.002012 --wait_timeout=3600 | tee verify.log
