# parse_ping.py
import re
import glob
import numpy as np

modes = ['native', 'bridge', 'host', 'container']

for mode in modes:
    ping_files = sorted(glob.glob(f'results_*/{mode}_ping_run*.txt'))
    if not ping_files:
        continue

    avg_rtts = []
    for f in ping_files:
        with open(f) as fp:
            content = fp.read()
            # Match "rtt min/avg/max/mdev = x/x/x/x ms"
            match = re.search(r'rtt min/avg/max/mdev = [\d.]+/([\d.]+)/[\d.]+/[\d.]+ ms', content)
            if match:
                avg_rtts.append(float(match.group(1)))

    print(f"[{mode}] Ping RTT: "
          f"mean={np.mean(avg_rtts):.3f} ms, "
          f"stddev={np.std(avg_rtts):.3f} ms")
