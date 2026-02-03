KinaCo (きなこ)
KinaCo は、AIチャットアプリです。AWS Cognitoによる認証と、AWS Lambdaを介したAIチャットロジックを統合しています。

特徴
🔐 Secure Auth: AWS Cognito Identity Providerを使用した堅牢なユーザー認証。
💬 AI Chat: AWSサービスと連携したリアルタイムなAIチャットボット機能。
📱 SwiftUI Native: 最新のSwiftUI API（@Observable, NavigationStackなど）を使用したスムーズなUI。
🎨 Modern Design: ピンクを基調とした、ファンコミュニティらしいモダンで親しみやすいデザイン。

技術スタック
Frontend: SwiftUI (iOS 17+)
Backend: AWS Cognito, AWS Lambda (via API Gateway)
Architecture: MVVM + Manager Pattern (Separation of Concerns)

環境変数の設定
プロジェクトの Config.xcconfig（または Info.plist）に以下のキーを設定してください。
・AWS_REGION: 使用するAWSリージョン (例: us-east-1)
・COGNITO_CLIENT_ID: AWS CognitoのアプリクライアントID
・API_BASE_URL: KinaCo API（Lambda）のエンドポイントURL
