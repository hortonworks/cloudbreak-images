#!/bin/bash

docker run -dt --name `basename $PWD` `basename $PWD`
