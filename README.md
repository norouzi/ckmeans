Cartesian k-means
=======

An implementation of *Cartesian k-means, M. Norouzi, D. J. Fleet, CVPR
2013*.

After downloading the datasets, and compiling the mex files, **RUN.m**
will take you through training and testing of qunatization algorithms,
which are useful for approximate Euclidean nearest neighbor search. <br/>
See **demo.m** for a sample run on sift_1M dataset.

### Compile

From within matlab please run the compile scripts (compile.m) in
utils/ and search/ sub-directories to build the mex files.

### Datasets

Download the INRIA bigann datasets (two SIFT datasets and one GIST
dataset) from http://corpus-texmex.irisa.fr/. Please make sure to
modify RUN.m to point INRIA_HOME to the root folder of these
datasets. INRIA_HOME folder should have the following sub-directories:
matlab/, which includes the matlab I/O functions, and ANN_SIFT1M/,
ANN_GIST1M/, and ANN_SIFT1B/, which include the training, and testing
sets.

You can also download the Tiny images dataset (80 million GIST
descriptors) from http://horatio.cs.nyu.edu/mit/tiny/data/index.html
modify RUN.m to point INRIA_HOME to the root folder it. Unfortunately
ground-truth nearest neighbor labels are not available for this
dataset.

### Contact

Copyright (c) 2013, Mohammad Norouzi \<mohammad.n@gmail.com\>. Please
don't hesitate to drop me a line for bug reports or general
comments. Thanks!

This is a free software; for license information please
refer to license.txt file.
