variable  "accessKey"{
    type = string
    default = "YOUR ACCESS KEY HERE"
}

variable  "secretKey"{
    type = string
    default = "YOUR SECRET KEY HERE"
}

variable  "region"{
    type = string
    default = "eu-central-1"
}

variable  "ami"{
    type = string
    default = "ami-05f7491af5eef733a"
}

variable  "instanceType"{
    type = string
    default = "t2.micro"
    
}

variable  "vm_names"{
    type = list(string)
    default = ["bestseller_webapp-01"]
}

variable  "bucket"{
    type = string
    default = "bestseller-files"
}

variable  "acl"{
    type = string
    default = "public-read"
}

variable  "bucketName"{
    type = string
    default = "readOnly-files"
}


variable  "environment"{
    type = string
    default = "Dev"
}

variable "publicKey"{
    type = string
    default = "YOUR PUIBLIC KEY HERE"
                
}