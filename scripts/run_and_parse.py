import subprocess
import re
import sys

def main():
    print("🚀 Starting Automated Hardware Verification...")
    
    print("🔨 Compiling RTL...")
    compile_cmd = ["iverilog", "-g2012", "-o", "cache_sim", 
                   "sim/tb_cache.sv", "src/cache_top.sv", 
                   "src/data_array.sv", "src/tag_array.sv"]
    
    compile_process = subprocess.run(compile_cmd, capture_output=True, text=True)
    if compile_process.returncode != 0:
        print("❌ Compilation Failed!")
        print(compile_process.stderr)
        sys.exit(1)

    print("🏃 Running Constrained Random Simulation...")
    sim_process = subprocess.run(["vvp", "cache_sim"], capture_output=True, text=True)
    
    output = sim_process.stdout
    print(output)
    
    match = re.search(r"Hit Rate:\s+([0-9\.]+)\%", output)
    if match:
        hit_rate = float(match.group(1))
        if hit_rate > 50.0:
            print(f"✅ PASSED: Hit rate of {hit_rate}% meets the requirement.")
            sys.exit(0)
        else:
            print(f"❌ FAILED: Hit rate of {hit_rate}% is too low. LRU logic may be broken.")
            sys.exit(1)
    else:
        print("❌ FAILED: Could not parse hit rate from simulation output.")
        sys.exit(1)

if __name__ == "__main__":
    main()
