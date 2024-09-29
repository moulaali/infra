from diagrams import Diagram, Cluster
from diagrams.aws.compute import EKS, ECS
from diagrams.aws.storage import EBS
from diagrams.aws.network import ELB
from diagrams.aws.general import Client
from diagrams.onprem.database import Mongodb  # Import MongoDB icon from on-prem category

# Create a new diagram
with Diagram("EKS Cluster with Containers, MongoDB Pod, and EBS Volumes", show=True):
    # A client (user)
    client = Client("User")
    
    # EKS Cluster with multiple nodes
    with Cluster("EKS Cluster"):
        
        # Define EKS nodes and the containers they host
        with Cluster("Node1"):
            eks_node1 = EKS("EKS Node1")
            node1_containers = [ECS("Container 1"), ECS("Container 2")]

        with Cluster("Node2"):
            eks_node2 = EKS("EKS Node2")
            node2_containers = [ECS("Container 3"), ECS("Container 4")]

        with Cluster("Node3"):
            eks_node3 = EKS("EKS Node3")
            node3_containers = [ECS("Container 5"), ECS("Container 6")]

        # Define a Pod inside Node3 to host MongoDB
        with Cluster("MongoDB Pod"):
            mongodb_pod = Mongodb("MongoDB")

        # Define EBS volumes for each node
        ebs_volumes = [EBS("EBS Volume 1"), EBS("EBS Volume 2"), EBS("EBS Volume 3")]

    # A load balancer to manage traffic
    lb = ELB("Load Balancer")
    
    # Connect client to the load balancer, then to EKS nodes
    client >> lb >> [eks_node1, eks_node2, eks_node3]
    
    # Attach each EKS node to its corresponding EBS volume
    eks_node1 - ebs_volumes[0]
    eks_node2 - ebs_volumes[1]
    eks_node3 - ebs_volumes[2]

    # MongoDB pod connected to EKS Node3
    eks_node3 - mongodb_pod

