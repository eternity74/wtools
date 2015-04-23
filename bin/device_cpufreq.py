#!/usr/bin/python
import sys, time,os
import subprocess
import re
import argparse

def adb_shell(cmd):
    adb_cmd = ["adb","shell",cmd]
    output = subprocess.check_output(adb_cmd)
    if args.verbose:
        print "[V] cmd=", cmd, " output=", output
    return output;

def check_file(path):
    print "checking %s..." % (path)
    output = adb_shell("ls -l %s" % path)
    found = False
    if "No such file or directory" not in output:
        print "%s ... ok" % (path)
        found = True
    else:
        print "%s ... nok" % (path)
    return found

def make_root():
    rooted = False
    cmd = ["adb","root"]
    output = subprocess.check_output(cmd)
    if output == "restarting adbd as root" or output == "adbd is already running as root":
        rooted = True
    return rooted

def make_device_script(rooted):
    # retrieve cpu info
    output = adb_shell("cat /proc/cpuinfo | grep -c processor")
    cpu_num=int(output)
    print "%d cpu(s) detected" % cpu_num

    # retrieve cpu clustering information
    cpu_cluster = {}
    max_freq_to_cpu = {}
    unresolved = []
    for i in range(cpu_num):
        cpuinfo_max_freq = adb_shell("cat /sys/devices/system/cpu/cpu%d/cpufreq/cpuinfo_max_freq" % i).strip()
        if "No such file or directory" in cpuinfo_max_freq:
            unresolved.append(i)
        else:
            scaling_governor = adb_shell("cat /sys/devices/system/cpu/cpu%d/cpufreq/scaling_governor" % i).strip()
            if max_freq_to_cpu.has_key(cpuinfo_max_freq) == False:
                max_freq_to_cpu[cpuinfo_max_freq]=i
            if cpu_cluster.has_key(max_freq_to_cpu[cpuinfo_max_freq]):
                cpu_cluster[max_freq_to_cpu[cpuinfo_max_freq]]['cpu'].append(i)
            else:
                cpu_cluster[i]={'cpuinfo_max_freq':int(cpuinfo_max_freq), 'scaling_governor':scaling_governor, 'cpu':[i]}

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
            script += "scaling_cur_freq[%d]=$(cat /sys/devices/system/cpu/cpu%d/cpufreq/scaling_cur_freq 2>/dev/null || echo 0)\n" % (i,i)
        else:
            script += "cpuinfo_cur_freq[%d]=$(cat /sys/devices/system/cpu/cpu%d/cpufreq/cpuinfo_cur_freq 2>/dev/null || echo 0)\n" % (i,i)
            script += "scaling_cur_freq[%d]=$(cat /sys/devices/system/cpu/cpu%d/cpufreq/scaling_cur_freq 2>/dev/null || echo 0)\n" % (i,i)

    script += 'format=""\n'
    script += 'args=""\n'

    for i in range(cpu_num):
        script += 'if [ -n "${cpu_max_freq[%d]}" ]; then\n' % i
        script += '    if [ ${cpu_max_freq[%d]} == ${scaling_max_freq[%d]} ]; then\n' % (i,i)
        script += '        format+="\e[39m\e[1m%-10s\e[0m\e[90m%-10s"\n'
        script += '    else\n'
        script += '        format+="\e[91m%-10s\e[31m%-10s"\n'
        script += '    fi\n'
        if rooted:
            script += '    args+=" ${scaling_max_freq[%d]} ${cpuinfo_cur_freq[%d]}"\n' % (i,i)
        else:
            script += '    args+=" ${cpu_max_freq[%d]} ${scaling_cur_freq[%d]}"\n' % (i,i)
        script += "else\n"
        script += '    format+="%-10s"\n'
        if rooted:
            script += '    args+=" ${cpuinfo_cur_freq[%d]}"\n' % (i)
        else:
            script += '    args+=" ${scaling_cur_freq[%d]}"\n' % (i)
        script += "fi\n"

    if rooted:
        script += 'printf $format $args\n'
        script += "echo \n"
    else:
        script += 'echo $args\n'

    script += "sleep $1\n"
    script += "done\n"
    f = open("cpufreq_d","w")
    f.write(script);
    f.close()

def install_device_script():
    os.system("adb push cpufreq_d /data/local/tmp/cpufreq")
    os.system("adb shell chmod 777 /data/local/tmp/cpufreq")

def main():
    global args
    parser = argparse.ArgumentParser()
    parser.add_argument("--verbose", "-v", action='store_true', help='verbose flag' )
    parser.add_argument("--interval","-i", default=1000.0, type=float, help='interval ms')
    parser.add_argument("--force","-f", action='store_true', help='always generate new script and install')
    args = parser.parse_args()

    logging = check_file("/system/xbin/busybox")

    if args.force or check_file("/data/local/tmp/cpufreq") == False:
        make_device_script(make_root())
        install_device_script()

    if logging == True:
        os.system("adb shell '/data/local/tmp/cpufreq %.1f| busybox tee /sdcard/cpufreq.log'" % (args.interval/1000))
    else:
        os.system("adb shell '/data/local/tmp/cpufreq %.1f'"% (args.interval/1000))

if __name__ == "__main__":
    main()
