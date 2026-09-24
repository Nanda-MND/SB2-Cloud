using System;
using System.Text;

namespace SB.SyncAgent
{
    internal class RC4Engine
    {
        public bool Encrypt()
        {
            bool toRet = true;
            try
            {
                long i = 0;
                long j = 0;
                Encoding enc_default = Encoding.Default;
                byte[] input = enc_default.GetBytes(m_sInClearText);
                byte[] output = new byte[input.Length];
                byte[] n_LocBox = new byte[m_nBoxLen];
                m_nBox.CopyTo(n_LocBox, 0);

                for (long offset = 0; offset < input.Length; offset++)
                {
                    i = (i + 1) % m_nBoxLen;
                    j = (j + n_LocBox[i]) % m_nBoxLen;
                    byte temp = n_LocBox[i];
                    n_LocBox[i] = n_LocBox[j];
                    n_LocBox[j] = temp;
                    byte a = input[offset];
                    byte b = n_LocBox[(n_LocBox[i] + n_LocBox[j]) % m_nBoxLen];
                    output[offset] = (byte)(a ^ b);
                }

                char[] outarrchar = new char[enc_default.GetCharCount(output, 0, output.Length)];
                enc_default.GetChars(output, 0, output.Length, outarrchar, 0);
                m_sCryptedText = new string(outarrchar);
            }
            catch
            {
                toRet = false;
            }
            return toRet;
        }

        public bool Decrypt()
        {
            bool toRet = true;
            try
            {
                m_sInClearText = m_sCryptedText;
                m_sCryptedText = "";
                if (toRet = Encrypt())
                    m_sInClearText = m_sCryptedText;
            }
            catch
            {
                toRet = false;
            }
            return toRet;
        }

        public string EncryptionKey
        {
            get { return m_sEncryptionKey; }
            set
            {
                if (m_sEncryptionKey == value) return;
                m_sEncryptionKey = value;

                long index2 = 0;
                Encoding ascii = Encoding.ASCII;
                Encoding unicode = Encoding.Unicode;
                byte[] asciiBytes = Encoding.Convert(unicode, ascii, unicode.GetBytes(m_sEncryptionKey));
                char[] asciiChars = new char[ascii.GetCharCount(asciiBytes, 0, asciiBytes.Length)];
                ascii.GetChars(asciiBytes, 0, asciiBytes.Length, asciiChars, 0);

                long keyLen = m_sEncryptionKey.Length;
                for (long count = 0; count < m_nBoxLen; count++)
                    m_nBox[count] = (byte)count;

                for (long count = 0; count < m_nBoxLen; count++)
                {
                    index2 = (index2 + m_nBox[count] + asciiChars[count % keyLen]) % m_nBoxLen;
                    byte temp = m_nBox[count];
                    m_nBox[count] = m_nBox[index2];
                    m_nBox[index2] = temp;
                }
            }
        }

        public string InClearText
        {
            get { return m_sInClearText; }
            set { if (m_sInClearText != value) m_sInClearText = value; }
        }

        public string CryptedText
        {
            get { return m_sCryptedText; }
            set { if (m_sCryptedText != value) m_sCryptedText = value; }
        }

        private string m_sEncryptionKey = "";
        protected byte[] m_nBox = new byte[m_nBoxLen];
        static public long m_nBoxLen = 255;
        private string m_sInClearText = "";
        private string m_sCryptedText = "";
    }
}
