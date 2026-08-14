# Variable specifying the drive you want to extend  
$drive_letter = "C"  
  
# Script to get the partition sizes and then resize the volume  
$size = (Get-PartitionSupportedSize -DriveLetter $drive_letter)  
Resize-Partition -DriveLetter $drive_letter -Size $size.SizeMax  
