# ofx-to-csv.rb

A program that can take the data from an ofx file, and will output a
folder hierarchy which contains all that data in CSV files.

## Install

    git clone git@github.com:Altece/ofx-to-csv.git
    cd ofx-to-csv
    bundle install

## Usage

    ./ofx-to-csv.rb /path/to/file.ofx [/path/to/desired/result]

If no path is given for a desired result, a new folder named `Finances.ofxcsv`
will be created, and will be where the results will be saved.

## References

This script was built using the [`ofx-parser` ruby gem][ofx-parser]
by [@aasmith][aasmith].

Ideas for how the script should behave were inspired by
[`ofx-to-csv` ruby gem][ofx-to-csv] by [@chrisroos][chrisroos].

Thanks for coming before me and providing me tools and ideas to solve this same problem!

[ofx-parser]: https://github.com/aasmith/ofx-parser.git
[ofx-to-csv]: https://github.com/chrisroos/ofx-to-csv.git

[aasmith]: https://github.com/aasmith
[chrisroos]: https://github.com/chrisroos
