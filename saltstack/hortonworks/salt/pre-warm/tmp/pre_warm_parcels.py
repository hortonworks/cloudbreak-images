#!/usr/bin/env python2

import os
import json
import errno
import subprocess
import tarfile

print "PRE_WARM_PARCELS: " + os.environ.get("PRE_WARM_PARCELS", "[]")
print "\n-------------\n"
print "PRE_WARM_CSD: " + os.environ.get("PRE_WARM_CSD", "[]")
print "\n-------------\n"

if os.environ.get("PRE_WARM_PARCELS", "[]"):
    PRE_WARM_PARCELS = json.loads(os.environ.get("PRE_WARM_PARCELS", "[]"))
    PRE_WARM_CSD = json.loads(os.environ.get("PRE_WARM_CSD", "[]"))
    PARCELS_ROOT = os.environ.get("PARCELS_ROOT", "/opt/cloudera/parcels")
    CSD_ROOT = os.environ.get("CSD_ROOT", "/opt/cloudera/csd")
    ACTIVE_PARCELS_PATH = "/var/lib/cloudera-scm-agent/active_parcels.json"
    CREATE_USERS = True
    PARCEL_REPO = "/opt/cloudera/parcel-repo"
    PARCEL_CACHE = "/opt/cloudera/parcel-cache"


# PRE_WARM_PARCELS = json.loads(os.environ.get("PRE_WARM_PARCELS", "[]"))
# PRE_WARM_CSD = json.loads(os.environ.get("PRE_WARM_CSD", "[]"))
# PARCELS_ROOT = os.environ.get("PARCELS_ROOT", "/home/workstation/dev/cloudera/cloudbreak-images/test-folder/proot")
# CSD_ROOT = os.environ.get("CSD_ROOT", "/home/workstation/dev/cloudera/cloudbreak-images/test-folder/csd")
# ACTIVE_PARCELS_PATH = "/home/workstation/dev/cloudera/cloudbreak-images/test-folder/active_parcels.json"
# CREATE_USERS = False
# PARCEL_REPO = "/home/workstation/dev/cloudera/cloudbreak-images/test-folder/prepo"
# PARCEL_CACHE = "/home/workstation/dev/cloudera/cloudbreak-images/test-folder/pcache"


    def mkdir_p(path):
        try:
            os.makedirs(path)
        except OSError as exc:  # Python >2.5
            if exc.errno == errno.EEXIST and os.path.isdir(path):
                pass
            else:
                raise


    def download(source, dest):
        cmd = "curl -C - -s -S --create-dirs {0} -o {1}".format(source, dest)
        if os.path.isfile(dest):
            try:
                subprocess.check_call(cmd, shell=True)
            except subprocess.CalledProcessError:
                os.unlink(dest)
                subprocess.check_call(cmd, shell=True)
        else:
            subprocess.check_call(cmd, shell=True)


    def normalize_url(url):
        if url.endswith("/"):
            return url[:-1]
        else:
            return url

    def check_if_string_in_file(fname, txt):
        with open(fname, 'r') as myfile:
            if txt in myfile.read():
                return true

    def download_parcel_checksum(url, dest):
        for ext in (".sha", ".sha1", ".sha256"):
            try:
                if os.path.exists(dest + ".sha"):
                    os.unlink(dest + ".sha")
                print "ZZZ Downloading checksum file:", dest + ".sha"
                print "ZZZ Url:", url
                print "ZZZ ext:", ext
                download(url + ext, dest + ".sha")
                print "Downloaded checksum file:", dest + ".sha"
                if check_if_string_in_file(dest + ".sha", "The specified key does not exist"):
                    raise Exception("wrong file:" + url + ext)
                else:
                    return ext
            except:
                pass
        raise Exception("failed to download parcel sha file")


    def activate_parcel(product, version):
        if os.path.isfile(ACTIVE_PARCELS_PATH):
            content = json.load(open(ACTIVE_PARCELS_PATH, "r"))
        else:
            content = {}
        content[product] = version

        json.dump(content, open(ACTIVE_PARCELS_PATH, "w"))


    def read_parcel_meta(parcel_path):
        p_tar = tarfile.open(parcel_path, encoding='utf-8')
        for tar_member in p_tar.getmembers():
            if tar_member.name.endswith("meta/parcel.json"):
                f = p_tar.extractfile(tar_member)
                return tar_member.name.split("/")[0], json.loads(f.read())
        raise Exception("failed to find parcel.json in file " + parcel_path)


    def place_parcel(parcel_path):
        base_folder, parcel_meta = read_parcel_meta(parcel_path)

        cmd = 'tar zxf "{0}" -C "{1}"'.format(parcel_path, PARCELS_ROOT)
        subprocess.check_call(cmd, shell=True)

        ln_cmd = 'cd {0}; ln -s {1} {2}'.format(PARCELS_ROOT, base_folder, parcel_meta["name"])
        subprocess.check_call(ln_cmd, shell=True)

        open(os.path.join(PARCELS_ROOT, parcel_meta["name"], ".dont_delete"), "w").close()
        activate_parcel(parcel_meta["name"], parcel_meta["version"])


    def place_parcels():
        for parcel_file_name, parcel_repository in PRE_WARM_PARCELS:
            parcel_url = normalize_url(parcel_repository) + "/" + parcel_file_name
            parcel_dest = os.path.join(PARCEL_REPO, parcel_file_name)
            print "Downloading parcel {0}, please wait ...".format(parcel_url)
            download(parcel_url, parcel_dest)
            print "Downloaded parcel:", parcel_url
            download_parcel_checksum(parcel_url, parcel_dest)
            # TODO call checksum here
            place_parcel(parcel_dest)


    def place_csds():
        for csd_url in PRE_WARM_CSD:
            if isinstance(csd_url, basestring):
                download(csd_url, os.path.join(CSD_ROOT, csd_url.split("/")[-1]))
                print "Downloaded CSD:", csd_url
            elif isinstance(csd_url, list):
                download(csd_url[0], os.path.join(CSD_ROOT, csd_url[1]))
                print "Downloaded CSD:", csd_url[0]


    def create_users():
        os.system("id -u cloudera-scm &>/dev/null || useradd -r cloudera-scm")


    def own_files():
        subprocess.check_call("chown -R cloudera-scm:cloudera-scm /opt/cloudera", shell=True)


    if PRE_WARM_PARCELS:
        # ensure cloudera user and folders is here

        mkdir_p(PARCEL_REPO)
        mkdir_p(PARCEL_CACHE)
        mkdir_p(PARCELS_ROOT)
        mkdir_p(CSD_ROOT)

        create_users()
        place_parcels()
        place_csds()
        subprocess.check_call("sync", shell=True)
        own_files()
