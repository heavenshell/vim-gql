import json
import sys


def main(lines):
    output = json.dumps(
        json.loads(lines.rstrip(' \t\r\n\0')),
        indent=2,
        ensure_ascii=False,
        separators=(',', ': '),
    )
    sys.stdout.write(output)


if __name__ == '__main__':
    lines = sys.stdin.readline()
    main(lines)
