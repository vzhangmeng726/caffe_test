#!/bin/bash

iter=1
while true; do
    echo "Start Training round ${iter}"
    # 1 delete temp file from last iteration
    if [ -f "yuanyang/cnn_master/build/feature.db" ]; then
        echo "delete feature.db"
        rm yuanyang/cnn_master/build/feature.db
    fi

    if [ -f "yuanyang/cnn_master/build/namelist.txt" ];then
        echo "delete namelist.txt"
        rm yuanyang/cnn_master/build/namelist.txt
    fi

    if [ -d "/home/yuanyang/data/db_data/triplet_train" ]; then
        echo "delete lmdb folder "
        rm -rf /home/yuanyang/data/db_data/triplet_train
    fi
    read -n1 -p "--> all temp files deleted ..."

    # link new caffemodel into working folder
    echo "link the model file into working folder..."
    ln -s "${PWD}/yuanyang/face_verfiry/triplet_loss_ext/small_maxout_triplet__iter_10000.caffemodel" "${PWD}/yuanyang/cnn_master/build/triplet_deploy.caffemodel"
    read -n1 -p "--> link file created ~"
    
    # 2 generate the new namelist.txt file, output file _--> namelist.txt feature.db 
    echo "generate the namelist.txt ..."
    cd ./yuanyang/cnn_master/build
    ./generate_triplet_pair /home/yuanyang/data/face_recognition/diaosi_crop/
    cd ../../../
    read -n1 -p "--> namelist generated ~"
    

    # move model file into "iter" subfolder
    if [ ! -d "yuanyang/face_verfiry/triplet_loss_ext/models/stage${iter}" ]; then
        echo "make dir stage${iter}"
        mkdir "yuanyang/face_verfiry/triplet_loss_ext/models/stage${iter}" -p
    fi
    echo "back the model files into stage${iter}"
    mv ./yuanyang/face_verfiry/triplet_loss_ext/*.caffemodel yuanyang/face_verfiry/triplet_loss_ext/models/stage${iter}
    mv ./yuanyang/face_verfiry/triplet_loss_ext/*.solverstate yuanyang/face_verfiry/triplet_loss_ext/models/stage${iter}
    read -n1 -p "--> mv models into stage folder done"
    
    # genearte new train lmdb 
    echo "generate new lmdb"
    ./build/tools/convert_imageset ""  yuanyang/cnn_master/build/namelist.txt  /home/yuanyang/data/db_data/triplet_train  -backend=lmdb -gray=true -shuffle=false -resize_width=144 -resize_height=144
    read -n1 -p "--> lmdb files generated done"

    # 3 train the model
    echo "Train new model"
    ./build/tools/caffe  train -solver yuanyang/face_verfiry/triplet_loss_ext/solver.prototxt -weights yuanyang/face_verfiry/triplet_loss_ext/models/stage${iter}/small_maxout_triplet__iter_10000.caffemodel 

    read -n1 -p "--> new model training done"

    # go next round
    let iter+=1
done
