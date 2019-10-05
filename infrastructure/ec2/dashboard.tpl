{
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 6,
            "width": 6,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "${project}", "FreeStorageSpace", "Devices", "${device_name}", { "id": "m1", "period": 60 } ],
                    [ "...", "Volumes", "nvme0n1p1", { "period": 60 } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${region}",
                "yAxis": {
                    "left": {
                        "min": 0
                    }
                },
                "period": 300
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/EC2", "CPUUtilization", "InstanceId", "${instance_id}", { "period": 60 } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${region}",
                "yAxis": {
                    "left": {
                        "min": 0
                    }
                },
                "period": 300
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/EC2", "CPUCreditBalance", "InstanceId", "${instance_id}", { "period": 60, "color": "#2ca02c" } ],
                    [ ".", "CPUCreditUsage", ".", ".", { "period": 60, "color": "#1f77b4" } ],
                    [ ".", "CPUSurplusCreditBalance", ".", ".", { "period": 60, "color": "#ff7f0e" } ],
                    [ ".", "CPUSurplusCreditsCharged", ".", ".", { "period": 60 } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${region}",
                "period": 300
            }
        },
        {
            "type": "metric",
            "x": 6,
            "y": 6,
            "width": 6,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/EC2", "NetworkIn", "InstanceId", "${instance_id}", { "period": 60 } ],
                    [ ".", "NetworkOut", ".", ".", { "period": 60 } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${region}",
                "yAxis": {
                    "left": {
                        "min": 0
                    }
                },
                "period": 300
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 6,
            "width": 6,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/EC2", "EBSReadBytes", "InstanceId", "${instance_id}", { "period": 60 } ],
                    [ ".", "EBSWriteBytes", ".", ".", { "period": 60 } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${region}",
                "period": 300,
                "yAxis": {
                    "left": {
                        "min": 0
                    }
                }
            }
        },
        {
            "type": "metric",
            "x": 18,
            "y": 6,
            "width": 6,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/EC2", "EBSIOBalance%", "InstanceId", "${instance_id}", { "period": 60 } ],
                    [ ".", "EBSByteBalance%", ".", ".", { "period": 60 } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${region}",
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": 100
                    }
                },
                "period": 300
            }
        }
    ]
}