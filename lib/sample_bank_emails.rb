# lib/sample_bank_emails.rb
module SampleBankEmails
  def self.samples
    {
      absa: {
        from: 'notifications@absa.co.za',
        body: <<~EMAIL
          Dear Customer,
          You have received a payment of R500.00 from JOHN DOE.
          Reference: ORDER-12345
          Date: #{Time.current.strftime('%Y-%m-%d')}
        EMAIL
      },
      fnb: {
        from: 'notifications@fnb.co.za', 
        body: <<~EMAIL
          FNB Notification:
          Credit: R750.50  
          Reference: ORDER-67890
          Available Balance: R12,345.67
        EMAIL
      },
      capitec: {
        from: 'notifications@capitecbank.co.za',
        body: <<~EMAIL
          Capitec Bank Notification:
          Amount: R1,200.00
          Ref: ORDER-54321
          Time: #{Time.current.strftime('%H:%M')}
        EMAIL
      }
    }
  end
end