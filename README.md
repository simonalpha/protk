 # protk ( Proteomics toolkit )


***
## What is it?

Protk is a wrapper for various proteomics tools. Initially it focusses on MS/MS database search and validation.

## Why do we need a wrapper around these tools

The aim of protk is present a consistent interface to numerous proteomics tools that is as uniform as possible. Protk also provides built-in support for submitting jobs to a cluster, and for managing protein databases. 

***



## basic installation
An installation script `setup.sh` is provided but it will not work unless some prior dependencies are already installed. You will need;


1. __TPP__ (Trans-Proteomic-Pipeline). Required to perform X!Tandem searches and to run PeptideProphet, iProphet and ProteinProphet
    Follow the [installation instructions](http://tools.proteomecenter.org/wiki/index.php?title=Software:TPP "tpp install instructions") provided by the institute for systems biology. Note that you don't need to worry about setting up the TPP web application.  Only the command-line tools are needed.  After installing the TPP tools make sure that they are in your `$PATH`.

2. __OMSSA__ (Search Engine). Required to perform OMSSA searches.
    Follow the [installation instructions](http://pubchem.ncbi.nlm.nih.gov/omssa/download.htm "omssa instructions") provided by NCBI.  After installing OMSSA make sure that the directory containing the OMSSA binaries (eg including the omssacl program ) is in your `$PATH`.

3. __Blast+__ (Blast+ executables). Required to build databases for OMSSA searches
    Follow the [installation instructions](http://blast.ncbi.nlm.nih.gov/Blast.cgi?CMD=Web&PAGE_TYPE=BlastDocs&DOC_TYPE=Download "blast install instructions") provided by NCBI (download Blast+ rather than the older legacy executables). After installing make sure that the directory containing the makeblastdb executable is in your `$PATH`.

4. __Configure Protk__ Finish the installation by running

        ./setup.sh 

    in the protk directory. This script will create symbolic links to TPP, OMSSA and Blast executables in `./bin/` (this can be changed by editing the config.yml script)




## Sequence databases

After running the setup.sh script you should run manage_db.rb to install specific sequence databases for use by the search engines. For example

    manage_db.rb -h
    manage_db.rb add -h #Get help on adding a database
    # Add a swissprot human database
    manage_db.rb add --ftp-source 'ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.fasta.gz ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/reldate.txt' --include-filters '/OS=Homo\ssapiens/' --id-regex 'sp\|.*\|(.*?)\s' --add-decoys --make-blast-index --archive-old sphuman

After first creating a database you can update it easily by running

    manage_db.rb update dbname

This will update the database only if any of its source files (or ftp release notes) have changed.

## Galaxy integration

Although all the protk tools can be run directly from the command-line a nicer way to run them (and visualise outputs) is to use the galaxy web application.

1. Check out and install the latest stable galaxy ([see the official galaxy wiki for more detailed setup instructions](http://wiki.g2.bx.psu.edu/Admin/Get%20Galaxy,"galaxy wiki"))

        hg clone https://bitbucket.org/galaxy/galaxy-dist 
		cd galaxy-dist
		sh run.sh

2. Make the protk tools available to galaxy. 
    - Create a directory for galaxy tool dependencies. It's best if this directory is outside the galaxy-dist directory. I usually create a directory called `tool_depends` alongside `galaxy-dist`.
    - Open the file `universe_wsgi.ini` in the `galaxy-dist` directory and set the configuration option `tool_dependency_dir` to point to the directory you just created
    - Create a symbolic link from the protk directory to the appropriate subdirectory of `<tool_dependency_dir>`. In the instructions below substitute 1.0.0 for the version number of [the protk galaxy tools](https://bitbucket.org/iracooke/protk-toolshed "protk galaxy tools") you are using.

            cd <tool_dependency_dir>
            mkdir protk
			cd protk
            mkdir 1.0.0
            ln -s 1.0.0 default
            ln -s <path_where_protk_was_installed> 1.0.0/bin

3. Configure the shell in which galaxy tools will run.
    - Create a symlink to the `env.sh` file so it will be sourced by galaxy as it runs each tool. This file should have been autogenerated by `setup.sh`

            ln -s <path_where_protk_was_installed>/env.sh 1.0.0/env.sh

4. Install the protk galaxy wrapper tools from the galaxy toolshed. 

