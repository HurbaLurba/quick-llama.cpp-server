import torch

print(f"PyTorch Version: {torch.__version__}")
print(f"Is CUDA (ROCm) available? {torch.cuda.is_available()}")
print(f"Number of GPUs: {torch.cuda.device_count()}")

if torch.cuda.is_available():
    print(f"Current GPU: {torch.cuda.get_device_name(0)}")
    
    # Simple test on the GPU: Perform a matrix multiplication
    try:
        a = torch.rand(1000, 1000).to('cuda')
        b = torch.rand(1000, 1000).to('cuda')
        c = a @ b # Matrix multiplication
        
        print("\nSuccessfully performed a matrix multiplication on the GPU.")
        print(f"Result shape: {c.shape}")
        
    except Exception as e:
        print(f"\nAn error occurred during GPU computation: {e}")
        print("This might indicate an issue with ROCm setup despite being detected.")
        
else:
    print("\nGPU is NOT available. Please check your ROCm installation and Docker setup.")
