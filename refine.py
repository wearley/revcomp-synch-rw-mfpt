#!/usr/bin/env python3
import argparse
import math

COMMENT_LINE='#'

def refine(file, skip=0):
    agg_mean = 0
    agg_err = 0
    agg_w = 0

    for line in file:
        line = line.strip()
        if line.startswith(COMMENT_LINE):
            continue
        if skip > 0:
            skip -= 1
            continue

        mean, err, w = line.split(',')
        mean = float(mean)
        err = float(err)
        w = int(w)

        agg_mean += w * mean
        agg_err += w * w * err * err
        agg_w += w

    agg_mean /= agg_w
    agg_err = math.sqrt(agg_err)
    agg_err /= agg_w

    inv_mean = 1.0 / agg_mean
    inv_err = agg_err * inv_mean * inv_mean

    return inv_mean, inv_err


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="")
    parser.add_argument('-s', '--skip', action='store', default=0, type=int,
                        help='number of output datums to skip')
    parser.add_argument('file', type=argparse.FileType('r'), nargs='*',
                        help='(clean) output file')

    args = parser.parse_args()
    skip = args.skip

    for fa in args.file:
        with fa as file:
            try:
                inv_mean, inv_err = refine(file, skip)
                print("%s mean: %r (±%r)" % (file.name, inv_mean, inv_err))
            except:
                print("%s error" % (file.name,))