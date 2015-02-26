#!/bin/python
import sys, time,os
import subprocess
import re


def make_root():
    cmd = ["adb","root"]
    output = subprocess.check_output(cmd)
    print output
    cmd = ["adb","wait-for-device"]
    output = subprocess.check_output(cmd)
    cmd = ["adb","remount"]
    output = subprocess.check_output(cmd)
    print output

# check busybox
def check_busybox():
    cmd = ["adb","shell","ls","-l","/system/xbin/busybox"]
    print "checking busybox...",
    output = subprocess.check_output(cmd)
    found = False
    if "No such file or directory" not in output:
        print "ok"
        print "The logs saved in /sdcard/cpufreq.log"
        found = True
    else:
        print "nok (Please push busybox to /system/xbin)"
    return found

def make_device_script():
    # retrieve cpu info
    cmd = ["adb","shell","cat","/proc/cpuinfo","|","grep","-c","\"processor\""]
    output = subprocess.check_output(cmd)
    cpu_num=int(output)

    # retrieve cpu clustering information
    cpu_cluster = {}
    for i in range(cpu_num):
        cmd = ["adb","shell","ls","-l","-d","/sys/devices/system/cpu/cpu%d/cpufreq" % i]
        cpufreq_dir = subprocess.check_output(cmd)
        if ">" not in cpufreq_dir:
            cmd = ["adb","shell","cat","/sys/devices/system/cpu/cpu%d/cpufreq/cpuinfo_max_freq" % i]
            cpuinfo_max_freq = subprocess.check_output(cmd)
            cmd = ["adb","shell","cat","/sys/devices/system/cpu/cpu%d/cpufreq/scaling_governor" % i]
            scaling_governor = subprocess.check_output(cmd)
            cpu_cluster[i]={'cpuinfo_max_freq':int(cpuinfo_max_freq), 'scaling_governor':scaling_governor.strip(), 'cpu':[i]}
    for i in range(cpu_num):
        cmd = ["adb","shell","ls","-l","-d","/sys/devices/system/cpu/cpu%d/cpufreq" % i]
        cpufreq_dir = subprocess.check_output(cmd)
        if ">" in cpufreq_dir:
            m = re.search("cpu(.)/cpufreq",cpufreq_dir)
            link_cpu = int(m.group(1))
            cpu_cluster[link_cpu]['cpu'].append(i)

    # make head message
    headstr = ""
    for cluster in cpu_cluster.keys():
        headstr += "%-10s" % "max"
        for i in cpu_cluster[cluster]['cpu']:
            headstr += "%-10s" % ("cpu%d" %i)

    # retrieve infomation
    #get_cpu_info_cmd = "adb shell 'echo"
    script = "#!/system/bin/sh\n"
    script += "echo interval $1\n"
    script += "echo '%s'\n" % headstr
    script += "while [ true ]; do\n"
    for i in range(cpu_num):
        if cpu_cluster.has_key(i):
            script += "cpu_max_freq[%d]=$(cat /sys/devices/system/cpu/cpu%d/cpufreq/cpuinfo_max_freq 2>/dev/null || echo 0)\n" % (i,i)
            script += "scaling_max_freq[%d]=$(cat /sys/devices/system/cpu/cpu%d/cpufreq/scaling_max_freq 2>/dev/null || echo 0)\n" % (i,i)
            script += "cpuinfo_cur_freq[%d]=$(cat /sys/devices/system/cpu/cpu%d/cpufreq/cpuinfo_cur_freq 2>/dev/null || echo 0)\n" % (i,i)
        else:
            script += "cpuinfo_cur_freq[%d]=$(cat /sys/devices/system/cpu/cpu%d/cpufreq/cpuinfo_cur_freq 2>/dev/null || echo 0)\n" % (i,i)

    script += 'format=""\n'
    script += 'args=""\n'
    for i in range(cpu_num):
        script += 'if [ -n "${cpu_max_freq[%d]}" ]; then\n' % i
        script += '    if [ ${cpu_max_freq[%d]} == ${scaling_max_freq[%d]} ]; then\n' % (i,i)
        script += '        format+="\e[39m\e[1m%-10s\e[0m\e[90m%-10s"\n'
        script += '    else\n'
        script += '        format+="\e[91m%-10s\e[31m%-10s"\n'
        script += '    fi\n'
        script += '    args+=" ${scaling_max_freq[%d]} ${cpuinfo_cur_freq[%d]}"\n' % (i,i)
        script += "else\n"
        script += '    format+="%-10s"\n'
        script += '    args+=" ${cpuinfo_cur_freq[%d]}"\n' % (i)
        script += "fi\n"

    script += 'printf $format $args\n'
    script += "echo \n"
    script += "sleep $1\n"
    script += "done\n"
    f = open("cpufreq_d","w")
    f.write(script);
    f.close()

def install_device_script():
    os.system("adb push cpufreq_d /system/xbin/cpufreq")
    os.system("adb shell chmod 777 /system/xbin/cpufreq")


def check_device_script():
    print "script ...",
    cmd = ["adb","shell","ls","-l","/system/xbin/cpufreq"]
    output = subprocess.check_output(cmd)
    found = False
    if "No such file or directory" not in output:
        print "ok"
        found = True
    else:
        print "nok"
    return found


def main():
    interval_ms=1000.0
    if len(sys.argv)>1:
        interval_ms=float(sys.argv[1])

    logging = check_busybox()

    if check_device_script() == False:
        make_root()
        make_device_script()
        install_device_script()

    if logging == True:
        os.system("adb shell 'cpufreq %.1f| busybox tee /sdcard/cpufreq.log'" % (interval_ms/1000))
    else:
        os.system("adb shell 'cpufreq $.1f'"% (interval_ms/1000))

if __name__ == "__main__":
    main()
