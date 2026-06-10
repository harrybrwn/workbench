variable "VERSION" {
    default = "0.0.1-alpha3"
}

variable "USER" {}

variable "GO_VERSION" {
  default = "1.26.3"
}

variable "RUST_VERSION" {
  default = "1.96.0"
}

group "default" {
    targets = [
        "workbench",
    ]
}

group "all" {
  targets = ["workbench", "workbench-dist"]
}

function "args" {
  params = [defaults]
  result = merge(
    {
        VERSION        = trimprefix(VERSION, "v")
        RUST_VERSION   = RUST_VERSION
        GO_VERSION     = GO_VERSION
        DEBIAN_VERSION = "trixie"
    },
    defaults,
  )
}

target "base" {
    context    = "."
    dockerfile = "Dockerfile"
    target     = "workbench"
    ssh        = ["default"]
}

target "workbench" {
    matrix = {
        item = [
            {
              DEBIAN_VERSION = "bookworm"
            },
            {
              DEBIAN_VERSION = "trixie"
            },
        ]
    }
    name       = "workbench_${item.DEBIAN_VERSION}"
    inherit    = ["base"]
    tags       = [
        "harrybrwn/workbench:${VERSION}-${item.DEBIAN_VERSION}"
    ]
    args = args({
        DEBIAN_VERSION = item.DEBIAN_VERSION
        USER           = USER
    })
}

target "workbench-dist" {
    matrix = {
        item = [
            {
              DEBIAN_VERSION = "bookworm"
            },
            {
              DEBIAN_VERSION = "trixie"
            },
        ]
    }
    name    = "workbench-dist_${item.DEBIAN_VERSION}"
    inherit = ["base"]
    ssh     = ["default"]
    tags    = [
        "harrybrwn/workbench-dist:${VERSION}-${item.DEBIAN_VERSION}"
    ]
    args = args({
        DEBIAN_VERSION = item.DEBIAN_VERSION
        USER           = USER
    })
    output = [
        "type=local,dest=docker-build"
    ]
}

target "test" {
    inherit = ["base"]
    target  = "test"
    tags    = ["workbench-test"]
    ssh     = ["default"]
    args    = args({
      DEBIAN_VERSION = "bookworm"
    })
}

target "builder" {
    inherit = ["base"]
    target  = "builder"
    tags    = ["workbench-builder"]
    args    = args({})
    ssh     = ["default"]
}
