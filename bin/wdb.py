#!/usr/bin/python

from httplib import HTTPResponse
import SocketServer
from socket import *
import thread,time,os,sys
import select, asyncore
import argparse
import json
import StringIO
import logging
from threading import current_thread

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

ch = logging.StreamHandler()
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
ch.setFormatter(formatter)

logger.addHandler(ch)

server_running=False

#find branch base version on http://omahaproxy.appspot.com/
# for 53.0.2785.94 branch-base-version 68623971be0cfc492a2cb0427d7f478e7b214c24
inspect_url = "http://chrome-devtools-frontend.appspot.com/serve_rev/@68623971be0cfc492a2cb0427d7f478e7b214c24/inspector.html"
#inspect_url = "http://chrome-devtools-frontend.appspot.com/serve_rev/@68623971be0cfc492a2cb0427d7f478e7b214c24/inspector.html"

running_threads = []
class MyTCPHandler(SocketServer.BaseRequestHandler):

    def getThreadName(self):
        return current_thread().getName()

    def handle(self):
        running_threads.append(current_thread())
        logger.debug("runnging thread %s",running_threads)
        logger.debug("%s is started", self.getThreadName())
        # self.request is the TCP socket connected to the client
        while True:
            if server_running==False:
                break
            head = self.request.recv(4)
            if not head:
               break
            elif len(head) != 4:
                continue
            l = int(head,16)
            logger.debug("%s %s wrote: %d", self.getThreadName(), self.client_address[0], l)
            self.command = self.request.recv(l).split(":")
            logger.debug("%s %s", self.getThreadName(), self.command)
            if  self.command[0] == 'host':
                self.handleHostCommand()
            elif self.command[0] == 'client':
                self.handleClientCommand()
            elif self.command[0] == 'shell':
                self.handleShellCommand()
            elif self.command[0] == 'localabstract':
                self.handleLocalabstractCommand()
                break
            else:
                logger.debug("%s unhandled %s",self.getThreadName(), self.command)
        logger.debug("[%s] is terminated",self.getThreadName())
        running_threads.remove(current_thread())

    def handleHostCommand(self):
        try:
            cmd = self.command[1]
            method = getattr(self,cmd)
            method()
        except AttributeError:
            logger.debug("%s not implemented %s",self.getThreadName(), self.command)
            #raise NotImplementedError("Class `{}` does not implement `{}`".format(self.__class__.__name__, method))

    def handleShellCommand(self):
        SEP = "======== output separator ========"

        net_unix = """
Num       RefCount Protocol Flags    Type St Inode Path
00000000: 00000002 00000000 00010000 0001 01 331813 /dev/socket/zygote
00000000: 00000002 00000000 00010000 0001 01 358606 @webos_devtools_remote_0
"""
        ps = """USER PID PPID VSIZE RSS WCHAN PC ? NAME
3 0 1 2 3 4 5 6 webos
"""
        user = """
Users:
  UserInfo{0:Test User:13} serialNo=0
    Created: <unknown>
    Last logged in: +17m18s871ms ago
  UserInfo{10:User with : (colon):10} serialNo=10
    Created: +3d4h35m1s139ms ago
    Last logged in: +17m26s287ms ago
"""
        if 'proc/net/unix' in self.command[1]:
            out = "webOS\n" + \
                  SEP + "\n" + \
                  "mStable=(0,50)-(720,1280)\n" + \
                  SEP + "\n" + \
                  ps+"\n" + \
                  SEP + "\n" + \
                  net_unix+"\n" + \
                  SEP + "\n" + \
                  user+"\n"
            self.sendOkay()
            self.responseCommand(out)

    def handleLocalabstractCommand(self): 
        self.sendOkay()
        device_socket = socket(AF_INET, SOCK_STREAM)

        #device_socket.connect(("localhost",9998))
        device_socket.connect((target_name,target_port))
        self.request.setblocking(False)
        device_socket.setblocking(False)

        http_mode = True

        while True:
            if server_running==False:
                logger.debug("%s server is shutdown", self.getThreadName())
                return
            if http_mode: # http mode
                toread = [self.request, device_socket]
                rready,wready,err = select.select( toread, [], [], 1 )
                for s in rready:
                    if s == self.request:
                        _out = self.request.recv(32*1024)
                        if not _out:
                            return
                        elif len(_out) > 0:
                            logger.debug("%s>>> %s",self.getThreadName() , _out)
                            device_socket.sendall(_out)
                    if s == device_socket:
                        _in = device_socket.recv(32*1024)
                        if not _in:
                            return
                        elif len(_in) > 0:
                            (status,headers,body) = self.parseHTTPMessage(_in)
                            # 1. modify devtoolsFrontendUrl
                            if 'devtoolsFrontendUrl' in body:
                                jdata = json.loads(body)
                                for d in jdata:
                                    if d.has_key('devtoolsFrontendUrl'):
                                        d['devtoolsFrontendUrl'] = d['devtoolsFrontendUrl'].replace("/devtools/inspector.html", inspect_url)
                                body = json.dumps(jdata)
                            # 2. make response
                            _to_chrome_out = status + "\r\n"
                            for h,v in headers:
                                if h == "Content-Length":
                                    v = len(body)
                                _to_chrome_out += "{}: {}\r\n".format (h,v)
                            _to_chrome_out += "\r\n"+body
                            logger.debug("%s<<< %s",self.getThreadName() , _to_chrome_out)
                            # 3. send the response
                            self.request.sendall(_to_chrome_out)
                        if status == "HTTP/1.1 101 WebSocket Protocol Handshake":
                            http_mode = False # upgrading to websocket mode
            else: # websocket mode - just connection each peer and let them communicate with each other
                toread = [self.request, device_socket]
                out_buffer = []
                in_buffer = []
                rready,wready,err = select.select( toread, [], [], 1 )
                for s in rready:
                    if s == self.request:
                        _out = self.request.recv(32*1024)
                        if not _out:
                            return
                        elif len(_out) > 0:
                            logger.debug("%s>>> %s",self.getThreadName() , _out)
                            device_socket.sendall(_out)
                    if s == device_socket:
                        _in = device_socket.recv(32*1024)
                        if not _in:
                            return
                        elif len(_in) > 0:
                            logger.debug("%s<<< %s",self.getThreadName() , _in)
                            self.request.sendall(_in)

    def sendOkay(self):
        self.request.sendall("OKAY")

    def devices(self):
        self.sendOkay()
        self.responseCommand('0123456789\twebOSdevice')

    def transport(self):
        self.sendOkay()


    def responseCommand(self,data):
        logger.debug("%s command:%s respond:%s",self.getThreadName(), self.command, data)
        l = len(data)
        out = '%04x%s' % (l,data)
        self.request.sendall(out)
    def parseHTTPMessage(self,msg):
        buf = StringIO.StringIO(msg)
        status = buf.readline().strip()
        headers = []
        while True:
            line = buf.readline()
            if line == "\r\n":
                break
            headers.append( line.strip().split(":") )
        body = buf.read()
        return (status, headers, body)

target_name, target_port = ("192.168.0.10", 9998)
if __name__ == "__main__":
    conf = "_wdb.conf"
    global args

    parser = argparse.ArgumentParser()
    parser.add_argument("--debug", "-d", action='store_true', help='logging for debug' )
    parser.add_argument("--show", "-s", action='store_true', help='show config' )
    parser.add_argument("--target_ip", "-ti", action='store', help='overide target-ip', default=None)
    parser.add_argument("--target_port", "-tp", action='store', help='overide target-port', default=None)
    args = parser.parse_args()

    confpath = conf
    if os.path.dirname(sys.argv[0]):
        confpath = os.path.dirname(sys.argv[0])+"/"+conf
    try:
        with open(confpath) as f:
            d = f.read().strip()
            if args.show:
                print "cat {}".format(confpath)
                print d
            t = d.split(" ")
            if len(t) == 1:
                target_name = t[0]
            elif len(t) == 2:
                (target_name, target_port) = (t[0],int(t[1]))
    except IOError:
        print "Need to setup target ip and port"
        print "ex)"
        print "echo '192.168.0.1 9998' > {}".format(confpath)

    if args.target_ip != None:
        target_name = args.target_ip
    if args.target_port != None:
        target_port = args.target_port
    if args.show:
        sys.exit(1)
    if args.debug:
        logger.setLevel(logging.DEBUG)

    print("------------------------------------------------------")
    print("STARTED: target {}:{}".format(target_name, target_port))
    HOST, PORT = "localhost", 5037

    # Create the server, binding to localhost on port 9999
    server = SocketServer.ThreadingTCPServer((HOST, PORT), MyTCPHandler)

    # Activate the server; this will keep running until you
    # interrupt the program with Ctrl-C
    server_running = True
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        logging.info("exiting...")
        server.server_close()
    server_running = False
