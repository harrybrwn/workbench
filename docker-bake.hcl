variable "VERSION" {
    default = "0.0.1"
}

#group "default" {
#    targets = [
#    ]
#}

target "workbench" {
    matrix = {
        item = [
            { RUST_VERSION = "1.84.0-bookworm", DEBIAN_VERSION = "bookworm" },
            { RUST_VERSION = "1.84.0-bullseye", DEBIAN_VERSION = "bullseye" },
        ]
    }
    name       = "workbench_${replace(item.RUST_VERSION, ".", "-")}_${item.DEBIAN_VERSION}"
    context    = "."
    dockerfile = "Dockerfile"
    target     = "workbench"
    ssh        = ["default"]
    tags       = [
        "harrybrwn/workbench:${VERSION}-${item.DEBIAN_VERSION}"
    ]
    args = {
        RUST_VERSION   = item.RUST_VERSION
        DEBIAN_VERSION = item.DEBIAN_VERSION
    }
}

target "workbench-dist" {
    matrix = {
        item = [
            { RUST_VERSION = "1.84.0-bookworm", DEBIAN_VERSION = "bookworm" },
            { RUST_VERSION = "1.84.0-bullseye", DEBIAN_VERSION = "bullseye" },
        ]
    }
    name       = "workbench-dist_${replace(item.RUST_VERSION, ".", "-")}_${item.DEBIAN_VERSION}"
    context    = "."
    dockerfile = "Dockerfile"
    target     = "workbench-dist"
    ssh        = ["default"]
    tags       = [
        "harrybrwn/workbench-dist:${VERSION}-${item.DEBIAN_VERSION}"
    ]
    args = {
        RUST_VERSION   = item.RUST_VERSION
        DEBIAN_VERSION = item.DEBIAN_VERSION
    }
    output = [
        "type=local,dest=docker-build"
    ]
}

target "builder" {
    context = "."
    dockerfile = "Dockerfile"
    target = "builder"
    tags = ["workbench-builder"]
    args = {
        RUST_VERSION   = "1.84.0-bookworm"
        DEBIAN_VERSION = "bookworm"
    }
    ssh = ["default"]
}
