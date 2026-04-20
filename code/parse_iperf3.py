# parse_iperf3.py
import json
import glob
import numpy as np

modes = ['native', 'bridge', 'host', 'container']

for mode in modes:
    tcp_files = sorted(glob.glob(f'results_*/{mode}_tcp_run*.json'))
    if not tcp_files:
        continue

    throughputs = []
    for f in tcp_files:
        with open(f) as fp:
            data = json.load(fp)
            # bits_per_second -> Gbps
            bps = data['end']['sum_received']['bits_per_second']
            throughputs.append(bps / 1e9)

    print(f"[{mode}] TCP Throughput: "
          f"mean={np.mean(throughputs):.3f} Gbps, "
          f"stddev={np.std(throughputs):.3f} Gbps")
