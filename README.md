# Build a Kubernetes cluster using Rancher via Ansible

Author: JD Black

## Introduction
I've spent the a few hours each day over the past couple weeks trying to setup a simple Kubernetes cluster (with great frustration and many restarts).  This is what I finally settled on for my low power environment using 3 AtomicPi servers and 4 Rasbperry Pi servers.

## Atomic Pi (x86) Kubernetex Cluster
The x86 Atomic Pi cluster consists of 3 single board computers (SBC).  Originally I was using Ubuntu Server 18.04 and everything seemed to work quite well, but since our industry is so Red Hat centric I though it best to restart using Centos 7.

I should say this was not my original approach.  Given the very limited resources on the AtomicPi SBC, I wanted to run a K3S cluster.  The K3S project does provide an ansible deployment solution in their GitHub repository, but I was never able to get it working under Centos 7.  As you'll see below, the K3S Ansible playbooks work great on the Raspberry Pis running Raspbian (Debian derivitave) so I fought it for quite a while before making a change in my approach.  In the end, I settled on using Rancher for my x86 Kubernetes cluster.

My Centos 7 Server setup is as follows:

1) Manually install bare metal (I know this should be automated...but I haven't built kickstarts yet)
   - Set US Central time
   - Automatic (default) partitioning reclaiming all space (note: the Atomic Pi only has 16G MMC locally)
   - Enable ethernet network and set hostname (My master is "alpha" and my two nodes are "beta" and "charlie")
   - Set root password
   - Create user for myself that is an administrator
2) Setup ssh access from my laptop: ssh-copy-id jd@hostname (note:  I've already created ssh keys)
3) Run Ansible to setup the master: ansible-playbook --ask-become-pass master.yml (from within atomic directory)
4) Wait about 15 minutes for the server to get itself initialized (note: these are not high performance SBCs)
5) Using your browser:
   - Connect to Rancher ("https://alpha" for my setup), create an admin password and accept terms.
   - Set the host URL (accept default for my setup- note this cannot be changed later).
   - Navigate to Cluster, click ["Add Cluster"](/img/Rancher_Add_Cluster.png), enter a name for your cluster (I'm using DevOpsForDefense), scroll down and click next.
   - On the next screen, select ["From Existing Nodes"](/img/Rancher_From_Existing_Nodes.png).  Scroll down and copy the token and ca-checksum from the [grey text](/img/Rancher_Node_Options.png) area and paste these into the /atomic/group_vars/all.yml (be sure to put them in quotes)
6) Run Ansible to setup the workers:  ansible-playbook --ask-become-pass node.yml
7) Now wait patiently for the workers to configure themselves into the cluster.  This will take a long time.  You can monitor progress on the Rancher dashboard (Cluster->Nodes).  It seems it takes the system a long time to stabalize and the dashboard will show errors along the way while things startup, so don't freak out if you see errors.  It took about 30 minutes for everything to stabilize and go green for me.
8) Once the nodes are provisioned, registered, [running "green"](/img/Rancher_Green.png), on your local machine install kubectl and create a file called ~/.kube/config.  Go to the cluster page in Rancher and click the ["Kubeconfig File" button](/img/Rancher_Kubeconfig_File.png).  Copy the contents presented into your ~/.kube/config file locally.
9) Test that everything is working by running "kubectl get nodes" on your local machine.  You should get a listing of the 2 agent nodes (bravo and charlie in my case), with their status (Ready).

That's it.  Your x86 Kubernetes cluster is ready to go!

One really nice Rancher feature you can take advantage of is that Rancher is a fully containerized Kubernetes solution.  I certainly took advantage of this fact while I was building and testing these playbooks.  If something goes terribly wrong, you can just clean up your containers and restart with a clean slate.

1) SSH into the machine you want to "clean".
2) Stop any running containers:  "sudo docker stop rancher-server" or "sudo docker stop rancher-agent" (note: there may be others that have been spawned...like etcd)
3) Clean up any non-running containers:  "sudo docker system prune" (enter y when prompted)
4) Verify your containers are cleaned up:  "sudo docker ps -a"
5) Do your debugging and then try to run the playbooks again.

A few caveats...or requests for help.  When building the Ansible playbooks I tried to use Ansible modules wherever possible, but I did run into a number of errors I didn't know how to correct (and Google-foo wasn't very helpful).  For example, I know there is a firewalld module I should be using to set port rules but for some reason I couldn't get Ansible to recognize these.  It may be due to me running Ubuntu on my "Ansible Server" (i.e. my laptop), but running Centos on the target machines I'm targeting.  When I ran into these roadblocks, I just switched over to a very non-idempotent (i.e. poor Ansible practice) approach of issuing command line configuration changes to the target machines.  I may go back and refine this over time if I learn more.  If you've got knowledge or experience, please let me know or put up a pull request with the recommended change.  I'll be happy to test and accept it to improve this solution.


## Raspberry Pi (ARM) Cluster

