using System;
using System.Diagnostics;
using System.IO;
using System.Threading.Tasks;

namespace DeploymentRunner
{
    class Program
    {
        // Global script paths
        private static readonly string AnythingLLMDeployScript = @"anythingllm-install\anythingllm.ps1";
        private static readonly string OllamaDeployScript = @"ollama-install\ollama.ps1";

        // Node deployments
        private static readonly string OllamaApiDeployScript = @"node-deployment-applications\ollama-api\ollama-api.ps1";

        private static readonly string PurgeAllScript = @"purge.ps1";
        private static readonly string PurgeAnythingLLMScript = @"anythingllm-install\purge-anythingLLM.ps1";
        private static readonly string PurgeOllamaScript = @"ollama-install\purge-ollama.ps1";

        private static readonly string PullOllamaModelScript = @"ollama-install\pull-model.ps1";

        static async Task Main(string[] args)
        {
            bool exit = false;
            while (!exit)
            {
                Console.Clear();
                Console.WriteLine("\n===== Main Menu =====\n");
                Console.WriteLine("[LLM Core Setup]");
                Console.WriteLine("1 - Start Ollama (language model engine)");
                Console.WriteLine("2 - Download Ollama Model");
                Console.WriteLine("3 - Start AnythingLLM (optional chat interface)");

                Console.WriteLine("\n[API Setup]");
                Console.WriteLine("4 - Start Ollama API (to use in apps or scripts)");

                Console.WriteLine("\n[Cleanup Tools]");
                Console.WriteLine("5 - Reset All Deployments");
                Console.WriteLine("6 - Reset AnythingLLM Setup");
                Console.WriteLine("7 - Reset Ollama Setup");

                Console.WriteLine("\nH - Help");
                Console.WriteLine("0 - Exit");
                Console.WriteLine("\n=====================");
                Console.Write("Enter your choice: ");
                string choice = Console.ReadLine()?.Trim().ToUpper();

                switch (choice)
                {
                    case "1":
                        await DeployOllamaAsync();
                        break;
                    case "2":
                        await PullOllamaModelAsync();
                        break;
                    case "3":
                        await DeployAnythingLLMAsync();
                        break;
                    case "4":
                        await DeployOllamaApiAsync();
                        break;
                    case "5":
                        await PurgeDockerContainersAsync(PurgeAllScript, "All deployments");
                        break;
                    case "6":
                        await PurgeDockerContainersAsync(PurgeAnythingLLMScript, "AnythingLLM setup");
                        break;
                    case "7":
                        await PurgeDockerContainersAsync(PurgeOllamaScript, "Ollama setup");
                        break;
                    case "H":
                        ShowHelp();
                        break;
                    case "0":
                        exit = true;
                        break;
                    default:
                        Console.WriteLine("Invalid choice, press Enter to try again...");
                        Console.ReadLine();
                        break;
                }
            }
        }

        static void ShowHelp()
        {
            Console.Clear();
            Console.WriteLine("\n===== Help Menu =====\n");
            Console.WriteLine("→ Ollama (1): Starts the language model engine.");
            Console.WriteLine("→ Download Model (2): Retrieves your chosen LLM model.");
            Console.WriteLine("→ AnythingLLM (3): Optional chat interface for interacting with the model.");
            Console.WriteLine("→ Ollama API (4): Makes the model accessible via a local API endpoint.");
            Console.WriteLine("\n→ Remove Options (5–7):");
            Console.WriteLine("   - Completely remove setups and files for a clean start.");
            Console.WriteLine("   - Use these only when you want to fully wipe out a component.");
            Console.WriteLine("\n=====================");
            Console.WriteLine("Press Enter to return to main menu...");
            Console.ReadLine();
        }



        // Deployment Methods
        static async Task DeployAnythingLLMAsync()
        {
            await DeployApplicationAsync(AnythingLLMDeployScript, "AnythingLLM");
        }

        static async Task DeployOllamaAsync()
        {
            await DeployApplicationAsync(OllamaDeployScript, "Ollama");
        }

        static async Task DeployOllamaApiAsync()
        {
            await DeployApplicationAsync(OllamaApiDeployScript, "Ollama API");
        }

        static async Task PullOllamaModelAsync()
        {
            Console.Clear();
            if (!File.Exists(PullOllamaModelScript))
            {
                Console.WriteLine($"Pull script not found: {PullOllamaModelScript}");
                return;
            }

            Console.WriteLine("Pulling Ollama model...");
            await ExecutePowerShellScriptAsync(PullOllamaModelScript);
        }

        // Purge Methods
        static async Task PurgeDockerContainersAsync(string scriptPath, string target)
        {
            Console.Clear();
            if (!File.Exists(scriptPath))
            {
                Console.WriteLine($"Purge script not found: {scriptPath}");
                return;
            }

            Console.WriteLine($"Purging {target}...");
            await ExecutePowerShellScriptAsync(scriptPath);
        }

        // Generic Deployment Execution Method
        static async Task DeployApplicationAsync(string scriptPath, string appName)
        {
            Console.Clear();
            if (!File.Exists(scriptPath))
            {
                Console.WriteLine($"Deployment script not found for {appName}: {scriptPath}");
                return;
            }

            Console.WriteLine($"Deploying {appName}...");
            await ExecutePowerShellScriptAsync(scriptPath);
        }

        // Script Execution Method
        static async Task ExecutePowerShellScriptAsync(string scriptPath)
        {
            Console.Clear();
            Console.WriteLine($"\nExecuting script: {scriptPath}");

            ProcessStartInfo psi = new ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = $"-NoProfile -ExecutionPolicy Bypass -File \"{scriptPath}\"",
                Verb = "runas",
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true
            };

            try
            {
                using (Process process = new Process { StartInfo = psi })
                {
                    process.Start();

                    string output = await process.StandardOutput.ReadToEndAsync();
                    string error = await process.StandardError.ReadToEndAsync();

                    await process.WaitForExitAsync();

                    if (process.ExitCode != 0)
                    {
                        Console.WriteLine($"Script finished with error code: {process.ExitCode}");
                        Console.WriteLine($"Error Output: {error}");
                    }
                    else
                    {
                        Console.WriteLine("Script executed successfully.");
                        Console.WriteLine(output);
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Failed to execute script: {ex.Message}");
            }
        }
    }
}
