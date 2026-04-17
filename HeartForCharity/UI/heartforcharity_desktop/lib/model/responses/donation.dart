class Donation {
  final int donationId;
  final int campaignId;
  final String? campaignTitle;
  final int? userProfileId;
  final String? donorName;
  final double amount;
  final bool isAnonymous;
  final String? payPalTransactionId;
  final String? status;
  final DateTime? donationDateTime;

  Donation({
    this.donationId = 0,
    this.campaignId = 0,
    this.campaignTitle,
    this.userProfileId,
    this.donorName,
    this.amount = 0,
    this.isAnonymous = false,
    this.payPalTransactionId,
    this.status,
    this.donationDateTime,
  });

  factory Donation.fromJson(Map<String, dynamic> json) => Donation(
        donationId: json['donationId'] ?? 0,
        campaignId: json['campaignId'] ?? 0,
        campaignTitle: json['campaignTitle'],
        userProfileId: json['userProfileId'],
        donorName: json['donorName'],
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        isAnonymous: json['isAnonymous'] ?? false,
        payPalTransactionId: json['payPalTransactionId'],
        status: json['status'],
        donationDateTime: json['donationDateTime'] != null
            ? DateTime.parse(json['donationDateTime'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'donationId': donationId,
        'campaignId': campaignId,
        'campaignTitle': campaignTitle,
        'userProfileId': userProfileId,
        'donorName': donorName,
        'amount': amount,
        'isAnonymous': isAnonymous,
        'payPalTransactionId': payPalTransactionId,
        'status': status,
        'donationDateTime': donationDateTime?.toIso8601String(),
      };
}
