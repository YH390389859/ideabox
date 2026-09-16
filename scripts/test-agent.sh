#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."
if [[ -z "${DEVELOPER_DIR:-}" && -d /Applications/Xcode-beta.app ]]; then
    export DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer
fi

agent_test_dir=$(mktemp -d /tmp/ideabox-agent-tests.XXXXXX)
trap 'rm -rf "$agent_test_dir"' EXIT

xcrun swiftc -swift-version 6 IdeaBox/AppModel.swift IdeaBox/AgentTools.swift \
    Tests/AppModelTests.swift -o "$agent_test_dir/models"
"$agent_test_dir/models"

xcrun swiftc -swift-version 6 IdeaBox/AppModel.swift IdeaBox/AgentTools.swift \
    Tests/AgentToolTests.swift -o "$agent_test_dir/tools"
"$agent_test_dir/tools"

xcrun swiftc -swift-version 6 IdeaBox/DeepSeekClient.swift \
    Tests/AgentProtocolTests.swift -o "$agent_test_dir/protocol"
"$agent_test_dir/protocol"

xcrun swiftc -swift-version 6 IdeaBox/DeepSeekClient.swift IdeaBox/AgentContext.swift \
    Tests/AgentContextTests.swift -o "$agent_test_dir/context"
"$agent_test_dir/context"

xcrun swiftc -swift-version 6 IdeaBox/AppModel.swift IdeaBox/AgentTools.swift \
    IdeaBox/DeepSeekClient.swift IdeaBox/AgentContext.swift IdeaBox/AgentConnection.swift IdeaBox/AgentCoordinator.swift \
    Tests/AgentCoordinatorTests.swift -o "$agent_test_dir/coordinator"
"$agent_test_dir/coordinator"

xcrun swiftc -swift-version 6 IdeaBox/SpeechInputDraft.swift \
    Tests/SpeechInputTests.swift -o "$agent_test_dir/speech-draft"
"$agent_test_dir/speech-draft"

xcrun swiftc -swift-version 6 -strict-concurrency=complete IdeaBox/SpeechRecognitionRecovery.swift \
    Tests/SpeechRecognitionRecoveryTests.swift -o "$agent_test_dir/speech-recovery"
"$agent_test_dir/speech-recovery"
