#!/usr/bin/env python3

import os
import json
import errno
import subprocess
import tarfile
import time
import functools
import hashlib

print("PRE_WARM_PARCELS: " + os.environ.get("PRE_WARM_PARCELS", "[]"))
print("\n-------------\n")
print("PRE_WARM_CSD: " + os.environ.get("PRE_WARM_CSD", "[]"))
print("\n-------------\n")

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

try:
    isinstance("", basestring)
    # Definition for Python 2.x
    def isstr(s):
        return isinstance(s, basestring)
except NameError:
    # Definition for Python 3.x
    def isstr(s):
        return isinstance(s, str)


    def retry(num_attempts=3, sleeptime_in_seconds=1):
        def decorator(func):
            @functools.wraps(func)
            def wrapper(*args, **kwargs):
                for i in range(num_attempts):
                    try:
                        return func(*args, **kwargs)
                    except Exception as e:
                        if i == num_attempts - 1:
                            raise
                        else:
                            print('Failed with error {0}, trying again'.format(e))
                            time.sleep(sleeptime_in_seconds)

            return wrapper

        return decorator

    def mkdir_p(path):
        try:
            os.makedirs(path)
        except OSError as exc:  # Python >2.5
            if exc.errno == errno.EEXIST and os.path.isdir(path):
                pass
            else:
                raise

    @retry(5, 2)
    def download(source, dest):
        cmd = "curl -s -S --create-dirs {0} -o {1} -L --fail".format(source, dest)
        if os.path.exists(dest):
            os.unlink(dest)
        subprocess.check_call(cmd, shell=True, stderr=subprocess.STDOUT)


    def normalize_url(url):
        if url.endswith("/"):
            return url[:-1]
        else:
            return url

    def check_if_string_in_file(fname, txt):
        with open(fname, 'r') as myfile:
            if txt in myfile.read():
                return True

    def download_parcel_checksum(url, dest):
        for ext in ("sha", "sha1", "sha256"):
            try:
                checksum_url = url + "." + ext
                download(checksum_url, dest + ".sha")
                print("Downloaded checksum file:", dest + ".sha")
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


    def verify_checksum(hash_method, parcel_dest):
        sha_hash = hashlib.sha1()
        if "sha256" == hash_method:
            sha_hash = hashlib.sha256()

        with open(parcel_dest,"rb") as f:
            for byte_block in iter(lambda: f.read(4096),b""):
                sha_hash.update(byte_block)

        if check_if_string_in_file(parcel_dest + ".sha", sha_hash.hexdigest()):
            print("Hash verification passed for {0}".format(parcel_dest))
        else:
            raise Exception("Hash verification failed for {0}".format(parcel_dest))


    def place_parcel(parcel_path):
        print("Place parcel: {0}".format(parcel_path))
        base_folder, parcel_meta = read_parcel_meta(parcel_path)
        subprocess.check_call("echo Decompress " + parcel_path, shell=True)

        cmd = 'tar zxf "{0}" -C "{1}"'.format(parcel_path, PARCELS_ROOT)
        subprocess.check_call(cmd, shell=True)

        ln_cmd = 'cd {0}; ln -s {1} {2}'.format(PARCELS_ROOT, base_folder, parcel_meta["name"])
        subprocess.check_call(ln_cmd, shell=True)

        open(os.path.join(PARCELS_ROOT, parcel_meta["name"], ".dont_delete"), "w").close()
        activate_parcel(parcel_meta["name"], parcel_meta["version"])
        check_storage()


    def place_parcels():
        for parcel_file_name, parcel_repository in PRE_WARM_PARCELS:
            subprocess.check_call("echo Download " + parcel_file_name, shell=True)
            parcel_url = normalize_url(parcel_repository) + "/" + parcel_file_name
            parcel_dest = os.path.join(PARCEL_REPO, parcel_file_name)
            print("Downloading parcel {0}, please wait ...".format(parcel_url))
            download(parcel_url, parcel_dest)
            print("Downloaded parcel:", parcel_url)
            hash_method = download_parcel_checksum(parcel_url, parcel_dest)
            verify_checksum(hash_method, parcel_dest)
            place_parcel(parcel_dest)
            check_storage()


    def place_csds():
        for csd_url in PRE_WARM_CSD:
            subprocess.check_call("echo Download " + csd_url, shell=True)
            if isstr(csd_url):
                download(csd_url, os.path.join(CSD_ROOT, csd_url.split("/")[-1]))
                print("Downloaded CSD:" + csd_url)
            elif isinstance(csd_url, list):
                download(csd_url[0], os.path.join(CSD_ROOT, csd_url[1]))
                print("Downloaded CSD:" + csd_url[0])
            check_storage()


    def create_users():
        os.system("id -u cloudera-scm &>/dev/null || useradd -r cloudera-scm")


    def own_files():
        subprocess.check_call("chown -R cloudera-scm:cloudera-scm /opt/cloudera", shell=True)

    def check_storage():
        cmd = 'df -h; du -h -d2 /opt/cloudera'
        subprocess.check_call(cmd, shell=True)

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
