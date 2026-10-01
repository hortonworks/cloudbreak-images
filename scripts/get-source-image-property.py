#!/usr/bin/env python3

import sys

PLAN_NAME_MAP = {
    "8.8":  "rhel-lvm88",
    "8.10": "rhel-lvm810",
    "9.5":  "rhel-lvm95",
    "9.6":  "rhel-lvm96",
    "9.8":  "rhel-lvm98",
}

# -----------------------------
# Rule-based mapping tables
# -----------------------------
IMAGE_RULES = {

    # ---------------- Azure ----------------
    ("Azure", "redhat8"): {
        "any":      "rhel-lvm810"
    },
    ("Azure", "redhat9"): {
        "base":     "rhel-lvm98",
        "freeipa":  "rhel-lvm98",
        ">=7.3.3":  "rhel-lvm98",
        "==7.3.2":  "rhel-lvm98"
    },

    # ---------------- AWS ----------------
    ("AWS", "redhat8", "arm64"): {
        "any":      "ami-05032c39067d77b1b"
    },
    ("AWS", "redhat8", "x86_64"): {
        "any":      "ami-02073841a355a1e92"
    },

    ("AWS", "redhat9", "arm64"): {
        "base":     "ami-06e87d669dc318713",
        "freeipa":  "ami-06e87d669dc318713",
        ">=7.3.3":  "ami-06e87d669dc318713",
        "==7.3.2":  "ami-06f1805217126b0d0",
    },
    ("AWS", "redhat9", "x86_64"): {
        "base":     "ami-08c9d8f6174932e4a",
        "freeipa":  "ami-08c9d8f6174932e4a",
        ">=7.3.3":  "ami-08c9d8f6174932e4a",
        "==7.3.2":  "ami-08a3a46b7bf22015a",
    },

    # ---------------- AWS Gov ----------------
    ("AWS_GOV", "redhat8"): {
        "any":      "ami-0ac4e06a69870e5be"
    },
    ("AWS_GOV", "redhat9"): {
        "any":      "ami-076ee76048eec9dd9"
    },

    # ---------------- GCP ----------------
    ("GCP", "redhat8"): {
        "any":      "rhel-8-byos-v20240709"
    },
    ("GCP", "redhat9"): {
        "base":     "rhel-9-byos-v20260811",
        "freeipa":  "rhel-9-byos-v20260811",
        ">=7.3.3":  "rhel-9-byos-v20260811",
        "==7.3.2":  "rhel-9-byos-v20250709",
    },

    # ---------------- OpenStack ----------------
    ("OpenStack", "redhat9"): {
        "any": "7a30c75a-9735-4ac9-a6dd-8086584bf661"
    },
}

# -----------------------------
# Parse version into a tuple
# -----------------------------
def parse_version(v_str: str) -> tuple:
    return tuple(map(int, v_str.split(".")))

# -----------------------------
# Version comparison
# -----------------------------
def compare_version(v1: str, v2: str) -> int:
    a = parse_version(v1)
    b = parse_version(v2)
    if a > b:
        return 1
    if a < b:
        return -1
    return 0

# -----------------------------
# Rule-based lookup
# -----------------------------
def lookup_image(provider: str, os: str, arch: str, image_type: str, sp_version: str) -> str:
    # Try exact match with arch
    key = (provider, os, arch)
    if key in IMAGE_RULES:
        rules = IMAGE_RULES[key]
    else:
        # Try match without arch
        key = (provider, os)
        if key not in IMAGE_RULES:
            raise ValueError(f"Unexpected combination: provider={provider}, os={os}, arch={arch}")
        rules = IMAGE_RULES[key]

    # Apply rules
    for rule, value in rules.items():
        if rule == "any":
            return value
        elif rule == image_type:
            return value
        elif rule.startswith(">="):
            if compare_version(sp_version, rule[2:]) >= 0:
                return value
        elif rule.startswith("<="):
            if compare_version(sp_version, rule[2:]) <= 0:
                return value
        elif rule.startswith("=="):
            if compare_version(sp_version, rule[2:]) == 0:
                return value
        elif rule.startswith(">"):
            if compare_version(sp_version, rule[1:]) > 0:
                return value
        elif rule.startswith("<"):
            if compare_version(sp_version, rule[1:]) < 0:
                return value

    raise ValueError(f"No matching rule for provider={provider}, os={os}, arch={arch}, version={sp_version}")

def lookup_plan_name(os_ver):
    result = PLAN_NAME_MAP.get(os_ver)
    if not result:
        raise ValueError(f"Unexpected OS version '{os_ver}' for planName!")
    return result

# -----------------------------
# CLI entry point
# -----------------------------
def main():
    if len(sys.argv) < 8:
        print("Usage:    get-source-image-property.py <selectedField> <cloudProvider> <imageOS> <imageOSVer> <imageArch> <imageType> <releaseVersion>")
        print("Example1: get-source-image-property.py imageId GCP redhat9 _ x86_64 runtime 7.3.2")
        print("Example2: get-source-image-property.py imageId AWS redhat8 _ arm64 base _")
        print("Example3: get-source-image-property.py imageId Azure redhat9 _ _ freeipa _")
        print(" '_' marks a wildcard value which is not necessary or not used anyway")
        sys.exit(1)

    selected_field = sys.argv[1]
    provider = sys.argv[2]
    image_os = sys.argv[3]
    image_os_ver = sys.argv[4]
    image_arch = sys.argv[5]
    image_type = sys.argv[6]
    release_version = sys.argv[7]

    # SP_VERSION = first 3 components of the version number
    sp_version = ".".join(release_version.split(".")[:3])

    if selected_field == "imageId":
        print(lookup_image(provider, image_os, image_arch, image_type, sp_version))
    elif selected_field == "planName":
        print(lookup_plan_name(image_os_ver))
    else:
        raise ValueError(f"Unknown selectedField '{selected_field}'")


if __name__ == "__main__":
    main()
