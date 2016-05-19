At my current company, we use [Vagrant](https://www.vagrantup.com) to create and maintain virtual machines in a reproducible manner. Our developers use their host machine to write code, then use a Vagrant VM to compile our application.

Vagrant can use [several technologies](https://www.vagrantup.com/docs/synced-folders/) to keep a folder on the host machine synchronized with the guest virtual machine: NFS, RSync, SMB, or Virtualbox. Each of these technologies has difference performance characteristics, which results in dramatically different compilation times, ranging from 30 seconds to over 5 minutes.

The workload when compiling our application is composed of small file reads interspersed with small file writes, in the range of 0.5KB to 8KB, with a few outliers in the 10s of KB -- nearly a worst-case workload for I/O. In this post, I will benchmark the synchronized folder options in Vagrant, and share our current best-practice for reducing compilation times.

## Benchmarking the synchronized folders

Using `dd` to read and write with block sizes 1KB, 4KB, and 16KB results in a workload similar to our compilation. The script for this experiment is provided near the end of this post. This test was run 3 times: all my results fell within 10% of one another. The host machine for this test was a 2013 MacBook Pro with an SSD, 16GB of RAM, and a 2.6 GHz Intel Core i7.

In this benchmark, "Native" refers to the native Virtualbox VM filesystem (which is not the same as the "Virtualbox" shared folder). It's also useful to understand that the "RSync" shared folder is really a native folder in the VM -- the only difference being that Vagrant exposes an easy to use `vagrant rsync` call on the host machine which synchronizes to this folder.

[![Vagrant Synchronized Folder Comparison]({{ site.baseurl }}/assets/vagrant_benchmark/VagrantSync.jpg)]({{ site.baseurl }}/assets/vagrant_benchmark/VagrantSync.svg)

It's clear from this comparison that there is an order of magnitude of performance difference between the native filesystem and the Virtualbox and NFS shared folders. Here is another copy of the graph, with only the slower choices:

[![Vagrant Slow Synchronized Folder Comparison]({{ site.baseurl }}/assets/vagrant_benchmark/VagrantSlowSync.jpg)]({{ site.baseurl }}/assets/vagrant_benchmark/VagrantSlowSync.svg)

These artificial benchmarks correlate closely with our measured compilation times:

|             | Virtualbox | NFS  | NFS (UDP) | RSync | Native |
| Time (m:ss) | 4:35       | 2:38 | 4:15      | 0:30  | 00:31  |

The significantly faster compilation times on NFS vs Virtualbox lend credence to my assertion that our compilation's reads and writes are mainly in the range of 0.5KB to 8KB, rather than 16KB+, where the Virtualbox shared folder has the lead.

#### Large block read/writes

Our workload doesn't have many larger read/writes, but here's a graph with those for anyone interested:

[![Vagrant Synchronized Folder Comparison - Big Blocks]({{ site.baseurl }}/assets/vagrant_benchmark/VagrantBigSync.jpg)]({{ site.baseurl }}/assets/vagrant_benchmark/VagrantBigSync.svg)

## Conclusions

Vagrant's shared folders are slow for intensive reads/writes of small files. It is an order of magnitude faster to use the native filesystem. At my current company, our workaround is to copy our source files from the shared folder into a temporary folder in the native filesystem, run the compilation there, and copy build artifacts back to the shared folder.

Vagrant's RSync shared folders operate in a similar manner: they copy content from the host machine into a native folder in the VM. However, the mechanics of using the RSync shared folder (sync is done on user command, not automatically, and sync is one-way) make it unwieldy for our use case.

Each underlying technology for a Vagrant shared folder has some strengths which may be important for a certain application. The choice of shared folder should be tied to the use case for Vagrant.

## Configuration files and test scripts

### Vagrantfile configuration

{% highlight ruby %}
    vm.synced_folder ".", "/vbox", type: "virtualbox"
    vm.synced_folder ".", "/nfs", type: "nfs",
      nfs_export: true,
      nfs_udp: false
    vm.synced_folder ".", "/nfsudp", type: "nfs",
      nfs_export: true,
      nfs_udp: true
    vm.synced_folder ".", "/rsync", type: "rsync",
      rsync__exclude: ".git/",
      rsync__auto: true
{% endhighlight %}

### Test scripts

#### For benchmarking the synchronized folder

{% highlight shell %}
for fs in "vbox" "nfs" "nfsudp" "rsync" "home/vagrant"
do
  for bs in 1 4 16
  do
    echo "Testing $fs $bs K write:"
    dd if=/dev/zero of=/$fs/test_$bs.tmp bs="$bs"k count=$((160000/$bs))
    sync; sleep 1
    echo "Testing $fs $bs K read:"
    dd of=/dev/null if=/$fs/test_$bs.tmp bs="$bs"k count=$((160000/$bs))
  done
  echo ""
done
{% endhighlight %}

#### For measuring compilation time

{% highlight shell %}
for fs in "vbox" "nfs" "nfsudp" "rsync" "home/vagrant"
do
  cd /$fs
  make clean >/dev/null 2>&1
  echo "Compiling for $fs"
  time sh -c "make >/dev/null 2>&1"
  make clean >/dev/null 2>&1
  echo ""
done
{% endhighlight %}
