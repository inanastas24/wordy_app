import SwiftUI

struct TranslationResultView: View {
    let result: TranslationResult
    var onClose: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Оригінальне слово
                Text(result.original)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                // Транскрипція IPA
                if let ipa = result.ipaTranscription {
                    Text(ipa)
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.textSecondary)
                }
                
                // Переклад
                Text(result.translation)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(AppColors.primary)
                
                Divider()
                
                // Приклади
                if !result.exampleSentence.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(result.exampleSentence)
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.textPrimary)
                            .italic()
                        
                        Text(result.exampleTranslation)
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                if let example2 = result.exampleSentence2,
                   let translation2 = result.exampleTranslation2,
                   !example2.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(example2)
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.textPrimary)
                            .italic()
                        
                        Text(translation2)
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
                
                // Кнопка закрити
                Button(action: onClose) {
                    Text("Закрити")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.primary)
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .background(AppColors.background)
    }
}
