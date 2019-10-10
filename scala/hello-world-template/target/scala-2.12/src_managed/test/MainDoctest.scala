



class MainDoctest
    extends _root_.org.scalatest.FunSpec
    with _root_.org.scalatest.Matchers
     {

  def sbtDoctestTypeEquals[A](a1: => A)(a2: => A): _root_.scala.Unit = {
    val _ = () => (a1, a2)
  }
  def sbtDoctestReplString(any: _root_.scala.Any): _root_.scala.Predef.String = {
    val s = _root_.scala.runtime.ScalaRunTime.replStringOf(any, 1000).init
    if (s.headOption == Some('\n')) s.tail else s
  }

  describe("Main.scala:11: removeVowels") {
    it("example at line 14: Solution.removeVowels(\"leetcodeisacommunityforcoders\")") {
      
      sbtDoctestReplString(Solution.removeVowels("leetcodeisacommunityforcoders")) should equal("\"ltcdscmmntyfrcdrs\"")
    }

    it("example at line 17: Solution.removeVowels(\"aeiou\")") {
      
      sbtDoctestReplString(Solution.removeVowels("aeiou")) should equal("\"\"")
    }

    it("example at line 20: Solution.removeVowels(\"leetcodeisacommunityforcoders\")") {
      sbtDoctestTypeEquals(Solution.removeVowels("leetcodeisacommunityforcoders"))((Solution.removeVowels("leetcodeisacommunityforcoders")): String)
      sbtDoctestReplString(Solution.removeVowels("leetcodeisacommunityforcoders")) should equal("\"ltcdscmmntyfrcdrs\"")
    }

    it("example at line 23: Solution.removeVowels(\"aeiou\")") {
      sbtDoctestTypeEquals(Solution.removeVowels("aeiou"))((Solution.removeVowels("aeiou")): String)
      sbtDoctestReplString(Solution.removeVowels("aeiou")) should equal("\"\"")
    }
  }

}
