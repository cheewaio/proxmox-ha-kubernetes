[control_planes]
%{ for node in control_planes ~}
${ replace(node.cidr, "/\\/.*/", "") } ansible_user=${ node.ciuser }
%{ endfor ~}

[workers]
%{ for node in workers ~}
${ replace(node.cidr, "/\\/.*/", "") } ansible_user=${ node.ciuser }
%{ endfor ~}