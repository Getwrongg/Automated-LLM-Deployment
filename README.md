# 🧠 DeploymentRunner

A simple, guided C# console tool that helps you deploy and manage local AI services — including **Ollama**, **AnythingLLM**, and **Ollama API** — without needing to understand Docker or write any terminal commands.

## 🚀 Features

- 🔹 One-click setup for Ollama and AnythingLLM
- 🔹 Optional API mode for using Ollama in your apps/scripts
- 🔹 Clear category-based menus
- 🔹 Safe removal options to cleanly wipe and reset components
- 🔹 Works on Windows (PowerShell-based execution)

---

## 📦 Supported Services

| Component         | Description                                                                 |
|------------------|-----------------------------------------------------------------------------|
| 🧠 **Ollama**      | Lightweight LLM runner for hosting models like `llama3`, `mistral`, etc.   |
| 💬 **AnythingLLM** | Web-based UI/chat interface to talk to your models (optional).             |
| 🛠️ **Ollama API**  | Exposes Ollama models as a simple HTTP API for integration into projects.  |

---

## 🖥️ Requirements

- Windows 10 or higher
- PowerShell 5.1 or later
- Git installed (if using AnythingLLM)
- Docker Desktop installed and running *(used under the hood)*

> ✅ You don't need to run Docker commands. This app handles all setup scripts for you.

---

## 📁 Project Structure

```
Automated-LLM-Deployment/
├── platform.deployment/
│   ├── anythingllm-install/
│   │   ├── anythingllm.ps1
│   │   ├── docker-compose.yml
│   │   ├── dockerfile
│   │   └── Firewall Powershell Script.txt
│   │
│   ├── docker-purge/
│   │   ├── purge.ps1
│   │   ├── purge-anythingllm.ps1
│   │   └── purge-ollama.ps1
│   │
│   ├── node-deployment-applications/
│   │   └── ollama-api/
│   │       ├── Dockerfile
│   │       ├── Ollama.zip
│   │       └── ollama-api.ps1
│   │
│   └── ollama-install/
│       ├── deploy-agents.ps1
│       └── docker-compose.yml
```


---

## 💡 Getting Started

1. **Clone this repo**
   ```bash
   git clone https://github.com/yourusername/DeploymentRunner.git
   cd DeploymentRunner
   ```

2. **Build the application**
   ```bash
   dotnet build
   ```

3. **Run the app**
   ```bash
   dotnet run
   ```

4. **Follow the interactive console**
   Choose actions like starting Ollama, deploying the API, or removing old setups.

---


## ❓ FAQ

### 🔧 Do I need Docker knowledge?
No. All script execution is abstracted behind simple menu options.

### 💬 Is AnythingLLM required?
No. You can skip it if you just want to use Ollama or the API.

### ♻️ How do I remove everything?
Use options `5–7` to remove all or individual setups cleanly.

---

## 🛠 Planned Features

- GUI version (WinForms or WPF)
- Model version selector
- Auto-update check
- Logs & error tracking

---

## 🤝 Contributing

Feel free to fork and submit pull requests. Ideas, bug reports, and feedback are welcome.

---

## 📄 License

MIT License © [Jacob Thompson](https://github.com/getwrwongg)
