#!/usr/bin/env python


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description='Combines assembly files into one file')
    parser.add_argument('in_files', metavar='F', type=str, nargs='+',
                        help='list of input files to combine')
    parser.add_argument('-o', dest='output', action='store', type=str, default='mmps.s',
                        help='location to put combined file')

    args = parser.parse_args()
    
    print "Merging files"
    with open(args.output, 'w') as output:
        for in_file in args.in_files:
            output.write('# %s\n\n' % in_file)
            with open(in_file, 'r') as asm_file:
                output.writelines(asm_file.readlines())

    print "Successfully merged files"

            
