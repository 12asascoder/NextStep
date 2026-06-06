# NextStep - AI Math Tutor

NextStep is an AI-powered math tutoring application consisting of an iOS frontend and a FastAPI backend. It leverages OpenAI's models to provide step-by-step math assistance to users.

## Project Structure

- **NextStep/**: The iOS application frontend. Built for iOS 16.0+, it is structured using the MVVM pattern (Models, Views, ViewModels, Services). 
- **Backend/**: The Python-based backend that handles the core AI logic. It uses FastAPI and interfaces with OpenAI's API to generate tutoring responses.

## Prerequisites

- **iOS**: macOS with Xcode 15+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen) installed.
- **Backend**: Python 3.11+ and [Poetry](https://python-poetry.org/) installed.
- **API Keys**: An OpenAI API key is required to run the backend.

## Getting Started

### 1. Running the Backend

The backend is built with FastAPI and uses Poetry for dependency management.

1. Navigate to the `Backend` directory:
   ```bash
   cd Backend
   ```
2. Install dependencies using Poetry:
   ```bash
   poetry install
   ```
3. Set up your environment variables. Create a `.env` file in the `Backend` directory and add your OpenAI API key:
   ```bash
   OPENAI_API_KEY=your_openai_api_key_here
   ```
4. Start the development server:
   ```bash
   poetry run uvicorn app.main:app --reload
   ```
   *(Note: Adjust `app.main:app` based on the exact entry point of your FastAPI application).*

### 2. Running the iOS App

The iOS project is generated using XcodeGen.

1. Navigate to the project root directory.
2. Generate the Xcode project file:
   ```bash
   xcodegen generate
   ```
3. Open the generated `NextStep.xcodeproj` in Xcode:
   ```bash
   open NextStep.xcodeproj
   ```
4. Select your desired simulator or device and hit **Run** (Cmd + R).

## Technologies Used

- **Frontend**: iOS, Swift, XcodeGen
- **Backend**: Python 3.11, FastAPI, Uvicorn, Pydantic
- **AI**: OpenAI API
