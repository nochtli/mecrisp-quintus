import serial
import sys

class Forth:
    def __init__(self, v=0):
        self.verbose = v

    def eprint(self, *args, **kwargs):
        if self.verbose:
            print(*args, file=sys.stderr, **kwargs)

    def open(self, *args, **kwargs):
        self.eprint(f'open {args}, {kwargs}')
        self.ser = serial.Serial(*args, **kwargs)

    def sendline(self, msg):
        self.ser.write(msg)
        self.rec = self.ser.readline()
        self.eprint(f'Rx: [{self.rec.decode().strip()}]')
        suf = self.rec.decode().strip()[-3:]
        return suf == "ok."

    def words(self):
        self.ser.write(b'words\n')
        buff = self.ser.readlines()
        self.rec = '\n'.join([i.decode().strip() for i in buff[:-1]])
        print(self.rec)
        suf = buff[-1].decode().strip()
        #self.eprint(f'{suf} , {suf == "ok."}')
        return suf == "ok."

    def upl_fast(self, fn):
        with open(fn, 'r') as fd:
            print(f'uploading: {fn}', end='\t')
            for ln in fd.readlines():
                data = ln.encode()
                ok = self.sendline(data)
                print('.', end='')
                if not ok:
                    print(f"?Err: {self.rec}", file=sys.stderr)
                    return 1
        print(" Done.");
        return 0

    def upl(self, fn):
        with open(fn, 'r') as fd:
            print(f'uploading: {fn}', end='\t')
            for ln in fd.readlines():
                data = ln.encode()
                self.ser.write(data)
                self.rec = self.ser.readlines()
                suf = self.rec[-1].decode().strip()[-3:]
                self.rec = '\n'.join([i.decode().strip() for i in self.rec])
                self.eprint(f'Rx: [{self.rec}]')
                print('.', end='')
                if suf != 'ok.':
                    print(f"?Err: {self.rec}", file=sys.stderr)
                    print(f'suf={suf}', end='')
                    return 1
        print(" Done.");
        return 0

    def command(self, cmd):
        for c in cmd:
            self.ser.write(c.encode())
            self.ser.write(b'\n')
            self.rec = self.ser.readlines()
            self.rec = '\n'.join([i.decode().strip() for i in self.rec])
            print(f'{self.rec}')

    def reset(self):
        self.ser.write(b'reset\n')
        self.rec = self.ser.readlines()
        self.rec = '\n'.join([i.decode().strip() for i in self.rec])
        self.eprint(f'{self.rec}')

    def eraseflash(self):
        self.ser.write(b'eraseflash\n')
        self.rec = self.ser.readlines()
        self.rec = '\n'.join([i.decode().strip() for i in self.rec])
        self.eprint(f'{self.rec}')

    def compilewhere(self):
        self.ser.write(b' compiletoram? .\n')
        self.rec = self.ser.readline().decode().strip()
        x = self.rec.split()
        res = not not int(x[2])
        #self.eprint(f'[{self.rec}] ans = {res}')
        return res

    def compiletoram(self):
        self.sendline(b'compiletoram\n')
        self.eprint(f'compiletoram? {self.compilewhere()}')
        assert True == self.compilewhere()

    def compiletoflash(self):
        self.sendline(b'compiletoflash\n')
        self.eprint(f'compiletoram? {self.compilewhere()}')
        assert False == self.compilewhere()



if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='Sends file to mecrisp')
    parser.add_argument('filenames', nargs='*')           # positional argument
    parser.add_argument('-v', '--verbose', action='store_true')  # on/off flag
    parser.add_argument('-r', '--reset', action='store_true')  # on/off flag
    parser.add_argument('-e', '--eraseflash', action='store_true')  # on/off flag
    parser.add_argument('-p', '--port', required=True, help='port')
    parser.add_argument('-b', '--baudrate', type=int, default=115200, help='Baud rate')
    parser.add_argument('-t', '--timeout', type=float, default=.01, help='Baud rate')
    parser.add_argument('-w', '--words', action='store_true', help='get all words')
    parser.add_argument('-A', '--command-after', nargs='*', help='execute command(s) after sending the files')
    parser.add_argument('-B', '--command-before', nargs='*',  help='execute command(s) before sending the files')
    group = parser.add_mutually_exclusive_group()
    group.add_argument('-F', '--compiletoflash', action='store_true')
    group.add_argument('-R', '--compiletoram', action='store_true')
    parser.add_argument('-V', '--version', action='version', version='%(prog)s 0.04')

    args = parser.parse_args()
    if args.verbose: print(f'args: {args}')

    f = Forth(args.verbose)
    f.open(args.port, args.baudrate, timeout=args.timeout, stopbits=serial.STOPBITS_TWO)
    if args.reset: f.reset()
    if args.eraseflash: f.eraseflash()
    if args.compiletoflash: f.compiletoflash()
    elif args.compiletoram: f.compiletoram()
    if args.command_before: f.command(args.command_before)
    for fn in args.filenames:
        f.sendline(b'\n')
        f.upl(fn)
    if args.words:
        f.words()
    if args.command_after: f.command(args.command_after)
