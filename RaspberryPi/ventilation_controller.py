import threading
import time
import serial
import datetime
import os
import errno
import sys
import socket

SERVER_PORT=12401
DEVICE = '/dev/ttyACM0' # the arduino serial interface (use dmesg when connecting)
BAUD = 9600
NR_SENSORS = 6
SENSOR_LOG_DIRECTORY = os.getenv("HOME") + '/SensorLogs/'
BATHROOM_MAX_HUMIDITY = 85
BATHROOM_HYSTERESIS = 1

#serial = serial.Serial(port=DEVICE, baudrate=BAUD, timeout=1.0)
#serial_read_fd = serial
#serial_write_fd = serial
# In order to start using serial port again, comment out two lines below, uncomment three above
# In shell:
# mkfifo /tmp/cmd_fifo
# mkfifo /tmp/rsp_fifo
# cat /tmp/rsp_fifo
# cat > /tmp/cmd_fifo
# Other minor changes made to the code are all marked with 'FOR TEST' label
serial_read_fd = open("/tmp/cmd_fifo", "r")
serial_write_fd = open("/tmp/rsp_fifo", "w")

serialWriteLock = threading.Lock()

print("Starting at: {0}".format(datetime.datetime.now()))

def writeCommand(command):
    serialWriteLock.acquire()
    print('Writing command: {}'.format(command))
    serial_write_fd.write(command)
    # flush is FOR TEST
    serial_write_fd.flush()
    serialWriteLock.release()

def mkdir_p(path):
    try:
        os.makedirs(path)
    except OSError as exc: # Python >2.5
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else: raise

class Place:
    def __init__(self, name, sensor_id, relay_id):
        self.name = name
        self.sensor_id = sensor_id
        self.relay_id = relay_id

bathroom = Place("Bathroom", 3, 2)
places = [bathroom, Place("Outside", 1, -1), Place("Hall", 5, 0), Place("Jasiu", 2, 5), Place("Study", 0, 4), Place("Bedroom", 4, 3)]

def same_hour(datetime1, datetime2):
    return (datetime1.year == datetime2.year) and (datetime1.month == datetime2.month) and (datetime1.day == datetime2.day) and (datetime1.hour == datetime2.hour)

class SensorReading:
    def __init__(self, date, humidity, temp):
        self.date = date
        self.humidity = humidity
        self.temperature = temp

    def __repr__(self):
        return "{}, {}, {}".format(self.date, self.humidity, self.temperature)

class Sensor:
    def __init__(self, place):
        self.place = place
        self.current_hour = []
        self.complete_hours = []
        self.last_reading = None
        self.lock = threading.Lock()

    def consume_complete_hours(self):
        self.lock.acquire()
        complete_hours = self.complete_hours
        self.complete_hours = []
        self.lock.release()
        return complete_hours

    def flush_hour(self):
        self.lock.acquire()
        self.complete_hours.append(self.current_hour)
        self.lock.release()
        self.current_hour = []

    def process_reading(self, humidity, temp):
        sensor_reading = SensorReading(datetime.datetime.now(), humidity, temp)
        if self.last_reading != None and not same_hour(self.last_reading.date, sensor_reading.date): 
            self.flush_hour()
        self.current_hour.append(sensor_reading)
        self.last_reading = sensor_reading 

sensors = []
id_to_sensor = {}
bathroom_sensor = None
for place in places:
    sensor = Sensor(place)
    sensors.append(sensor)
    id_to_sensor[place.sensor_id] = sensor 
    if place == bathroom:
        bathroom_sensor = sensor


def process_sensor_reading(sensor_id, humidity, temperature):
    global is_on
    sensor = id_to_sensor[sensor_id]
    if sensor is None:
        print('Warning: unknown sensor_id {0}, reading {}, {}'.format(sensor_id, humidity, temperature))
        return

    sensor.process_reading(humidity, temperature)

class StoppableThread(threading.Thread):
    def __init__(self):
        super(StoppableThread, self).__init__()
        self.keepRunning = True

    def loop(self):
        pass

    def run(self):
        while self.keepRunning:
            self.loop()

    def stop(self):
        self.keepRunning = False

class ReadingThread(StoppableThread):
    def __init__(self):
        super(ReadingThread, self).__init__()
        self.line = ""

    def loop(self):
        # FOR TEST: read(1) guarantees no buffering
        self.line += serial_read_fd.read(1)
        print("Got: {}".format(self.line));
        while '\n' in self.line:
            headTail = self.line.split('\n', 1)
            line = headTail[0]
            if line.startswith("s,"):
                tokens = line.split(',')
                if tokens[2] == "OK":
                    process_sensor_reading(int(tokens[1]), float(tokens[3]), float(tokens[4]))
            else:
                print("Unknown message: {0}".format(line))
            self.line = headTail[1]

class SamplingThread(StoppableThread):
    def __init__(self):
        super(SamplingThread, self).__init__()

    def loop(self):
        time.sleep(3)
        for i in range(NR_SENSORS):
            writeCommand("s{0}$".format(i))
            time.sleep(0.1)

class WriteoutThread(StoppableThread):
    def __init__(self):
        super(WriteoutThread, self).__init__()

    def writeout_hour(self, place, hour):
        if len(hour) == 0:
            return
        date = hour[0].date
        hour_dir = "{0}/{1}/{2:0>4}/{3:0>2}/{4:0>2}/{5:0>2}".format(SENSOR_LOG_DIRECTORY, place.name, date.year, date.month, date.day, date.hour)
        mkdir_p(hour_dir)
        out_file = open(hour_dir+"/sensor.log", "w")
        for reading in hour:
            out_file.write("{}\n".format(str(reading)))
        out_file.close()

    def loop(self):
        time.sleep(1)
        for sensor in sensors:
            complete_hours = sensor.consume_complete_hours()
            for complete_hour in complete_hours:
                self.writeout_hour(sensor.place, complete_hour)

class VentilationThread(StoppableThread):
    def __init__(self):
        super(VentilationThread, self).__init__()
        self.is_on = False
        writeCommand("r2,{0}$".format(int(self.is_on)))

    def loop(self):
        time.sleep(1)
        last_reading = bathroom_sensor.last_reading
        if last_reading == None:
            return
        want_on = last_reading.humidity > BATHROOM_MAX_HUMIDITY + BATHROOM_HYSTERESIS
        want_off = last_reading.humidity <= BATHROOM_MAX_HUMIDITY - BATHROOM_HYSTERESIS
        if (want_on and not self.is_on) or (want_off and self.is_on):
            switching_on = want_on
            print("Date: {0}, switching on: {1}, due to reading: {2}".format(datetime.datetime.now(), int(switching_on), str(last_reading)))
            writeCommand("r2,{0}$".format(int(switching_on)))
            self.is_on = switching_on

class ServerThread(StoppableThread):
    def __init__(self):
        super(ServerThread, self).__init__()
        self.socket = socket.socket()
        self.socket.bind(('', SERVER_PORT))
        self.partial_message = ''
        self.client = None

    def process_message(self, message):
        message = message.lstrip('\n')
        print("Processing message: {}".format(message))
        if message.startswith('s'):
            sensor_id = int(message[1:])
            print("Requested reading of sensor: {}".format(sensor_id))

    def process_input(self, message):
        self.partial_message += message
        while '$' in self.partial_message:
            headTail = self.partial_message.split('$', 1)
            one_message = headTail[0]
            self.process_message(one_message)
            self.partial_message = headTail[1]
            self.client.send("blaha")

    def loop(self):
        self.socket.listen(1)
        c, addr = self.socket.accept()
        print('Got connection from {}'.format(addr))
        self.client = c
        while True:
            msg = c.recv(1024)
            if msg == "":
                print('Connection from {} closed'.format(addr))
                break
            self.process_input(msg)

readingThread = ReadingThread()
readingThread.start()
samplingThread = SamplingThread()
samplingThread.start()
writeoutThread = WriteoutThread()
writeoutThread.start()
ventilationThread = VentilationThread()
ventilationThread.start()
serverThread = ServerThread()
serverThread.start()
threads = [readingThread, samplingThread, writeoutThread, ventilationThread, serverThread]
try:
    while True:
        time.sleep(1)
        sys.stdout.flush()
except:
    print 'Interrupt'
    os._exit(0)
    # The below attempts to exit nicely, but doesn't work for blocking calls :(
    for thread in threads:
        thread.stop()
        while thread.isAlive():
            thread.join(0.5)
finally:
    print 'Exiting'
    os._exit(0)
