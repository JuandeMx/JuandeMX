import socket, threading, select, sys, time

# Config
LISTENING_ADDR = '0.0.0.0'
LISTENING_PORT = 80
BUFLEN = 4096 * 4
TIMEOUT = 60
DEFAULT_HOST = '127.0.0.1:44'
# Cloudflare compatible response (101 Switching Protocols)
RESPONSE_WS = b'HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n'
# Standard response for non-WS
RESPONSE_STD = b'HTTP/1.1 200 Connection Established\r\n\r\n'

class Server(threading.Thread):
    def __init__(self, host, port):
        threading.Thread.__init__(self)
        self.running = False
        self.host = host
        self.port = port
        self.threads = []
        self.threadsLock = threading.Lock()

    def run(self):
        try:
            self.soc = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.soc.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            self.soc.settimeout(2)
            self.soc.bind((self.host, self.port))
            self.soc.listen(100)
            self.running = True

            while self.running:
                try:
                    c, addr = self.soc.accept()
                    c.setblocking(1)
                except socket.timeout:
                    continue
                conn = ConnectionHandler(c, self, addr)
                conn.start()
                self.addConn(conn)
        except Exception as e:
            pass
        finally:
            self.running = False
            self.soc.close()

    def addConn(self, conn):
        with self.threadsLock:
            if self.running:
                self.threads.append(conn)

    def removeConn(self, conn):
        with self.threadsLock:
            if conn in self.threads:
                self.threads.remove(conn)

    def close(self):
        self.running = False
        with self.threadsLock:
            for c in list(self.threads):
                try: c.close()
                except: pass

class ConnectionHandler(threading.Thread):
    def __init__(self, socClient, server, addr):
        threading.Thread.__init__(self)
        self.clientClosed = False
        self.targetClosed = True
        self.client = socClient
        self.server = server
        self.addr = addr
        self.target = None

    def run(self):
        try:
            client_buffer = self.client.recv(BUFLEN)
            if not client_buffer: return

            # Detect WebSocket or standard request
            if b'websocket' in client_buffer.lower():
                self.target = socket.create_connection(('127.0.0.1', 44), timeout=TIMEOUT)
                self.targetClosed = False
                self.client.sendall(RESPONSE_WS)
            else:
                self.target = socket.create_connection(('127.0.0.1', 44), timeout=TIMEOUT)
                self.targetClosed = False
                self.client.sendall(RESPONSE_STD)

            self.doCONNECT()
        except Exception as e:
            pass
        finally:
            self.close()
            self.server.removeConn(self)

    def close(self):
        try:
            if not self.clientClosed:
                self.client.shutdown(socket.SHUT_RDWR)
                self.client.close()
        except: pass
        finally: self.clientClosed = True

        try:
            if self.target and not self.targetClosed:
                self.target.shutdown(socket.SHUT_RDWR)
                self.target.close()
        except: pass
        finally: self.targetClosed = True

    def doCONNECT(self):
        socs = [self.client, self.target]
        count = 0
        while True:
            count += 1
            (recv, _, err) = select.select(socs, [], socs, 3)
            if err: break
            if recv:
                for in_ in recv:
                    try:
                        data = in_.recv(BUFLEN)
                        if data:
                            out = self.target if in_ is self.client else self.client
                            out.sendall(data)
                            count = 0
                        else: return
                    except: return
            if count == 60: break

def main():
    server = Server('0.0.0.0', 80)
    server.start()
    while True:
        try: time.sleep(2)
        except KeyboardInterrupt:
            server.close()
            break

if __name__ == '__main__':
    main()
