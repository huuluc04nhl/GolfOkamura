/// Model tin nhắn hội thoại giữa Golfer và Okamura AI Caddie
class ChatMessageModel {
  final String id;
  final bool isUser;
  final String text;
  final DateTime timestamp;
  final List<String> quickPrompts;
  final String? actionRoute;
  final String? actionLabel;
  final String? serviceRequestTitle;
  final int? autoExecuteCountdown;
  final bool isAutoExecuted;
  final bool isLoading;

  const ChatMessageModel({
    required this.id,
    required this.isUser,
    required this.text,
    required this.timestamp,
    this.quickPrompts = const [],
    this.actionRoute,
    this.actionLabel,
    this.serviceRequestTitle,
    this.autoExecuteCountdown,
    this.isAutoExecuted = false,
    this.isLoading = false,
  });

  ChatMessageModel copyWith({
    String? id,
    bool? isUser,
    String? text,
    DateTime? timestamp,
    List<String>? quickPrompts,
    String? actionRoute,
    String? actionLabel,
    String? serviceRequestTitle,
    int? autoExecuteCountdown,
    bool? isAutoExecuted,
    bool? isLoading,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      isUser: isUser ?? this.isUser,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      quickPrompts: quickPrompts ?? this.quickPrompts,
      actionRoute: actionRoute ?? this.actionRoute,
      actionLabel: actionLabel ?? this.actionLabel,
      serviceRequestTitle: serviceRequestTitle ?? this.serviceRequestTitle,
      autoExecuteCountdown: autoExecuteCountdown ?? this.autoExecuteCountdown,
      isAutoExecuted: isAutoExecuted ?? this.isAutoExecuted,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
