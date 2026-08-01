// ==========================================================================
// 预置数据：50核心词 / 12成就 / 7亲密度解锁 / 默认玩家 / 默认星回设置
// ==========================================================================
class SampleData {
  // 50个核心高频词：(word, phonetic, meaning, example, word_type: read/write, frequency)
  static const List<(String,String,String,String,String,int)> kWords50 = [
    ('ubiquitous','/juːˈbɪkwɪtəs/','adj. 无处不在的','Smartphones have become ubiquitous in modern life.','write',1),
    ('ephemeral','/ɪˈfemərəl/','adj. 短暂的','Fame in the digital age is often ephemeral.','read',1),
    ('pragmatic','/præɡˈmætɪk/','adj. 务实的','We need a pragmatic approach to solve this.','read',1),
    ('meticulous','/məˈtɪkjələs/','adj. 一丝不苟的','She is meticulous about grammar.','write',1),
    ('ambiguous','/æmˈbɪɡjuəs/','adj. 模棱两可的','The statement was deliberately ambiguous.','read',1),
    ('resilient','/rɪˈzɪliənt/','adj. 有韧性的','Children are often surprisingly resilient.','write',1),
    ('eloquent','/ˈeləkwənt/','adj. 雄辩的','He gave an eloquent speech.','read',1),
    ('diligent','/ˈdɪlɪdʒənt/','adj. 勤勉的','She is a diligent student.','write',1),
    ('profound','/prəˈfaʊnd/','adj. 深刻的','The film had a profound impact.','write',1),
    ('benevolent','/bəˈnevələnt/','adj. 仁慈的','A benevolent smile crossed his face.','read',0),
    ('tenacious','/təˈneɪʃəs/','adj. 顽强的','She was tenacious in pursuit of her goals.','write',1),
    ('versatile','/ˈvɜːrsətl/','adj. 多才多艺的','He is a versatile actor.','write',1),
    ('coherent','/koʊˈhɪrənt/','adj. 连贯的','Write a coherent essay.','write',1),
    ('empirical','/ɪmˈpɪrɪkl/','adj. 以经验为依据的','There is no empirical evidence.','read',1),
    ('sophisticated','/səˈfɪstɪkeɪtɪd/','adj. 复杂精密的','Highly sophisticated software.','read',1),
    ('conscientious','/ˌkɒnʃiˈenʃəs/','adj. 尽责的','She is a conscientious worker.','write',0),
    ('exemplary','/ɪɡˈzempləri/','adj. 典范的','His behavior was exemplary.','write',1),
    ('innate','/ɪˈneɪt/','adj. 与生俱来的','He has an innate talent.','read',1),
    ('scrutinize','/ˈskruːtɪnaɪz/','v. 仔细审查','We must scrutinize the data.','write',1),
    ('alleviate','/əˈliːvieɪt/','v. 缓解','The drug alleviates pain.','write',1),
    ('bolster','/ˈboʊlstər/','v. 增强','We need to bolster confidence.','write',1),
    ('cultivate','/ˈkʌltɪveɪt/','v. 培养','Cultivate good habits.','write',1),
    ('deteriorate','/dɪˈtɪriəreɪt/','v. 恶化','His health deteriorated.','read',1),
    ('elicit','/ɪˈlɪsɪt/','v. 引出','Elicit a response.','write',0),
    ('foster','/ˈfɒstər/','v. 促进','Foster a sense of community.','write',1),
    ('hinder','/ˈhɪndər/','v. 阻碍',"Don't hinder progress.",'write',1),
    ('implement','/ˈɪmplɪment/','v. 实施','Implement the plan.','write',1),
    ('jeopardize','/ˈdʒepərdaɪz/','v. 危及','It could jeopardize the deal.','write',0),
    ('mitigate','/ˈmɪtɪɡeɪt/','v. 减轻','Mitigate the risk.','write',1),
    ('perpetuate','/pərˈpetʃueɪt/','v. 使永存',"Don't perpetuate myths.",'read',0),
    ('rectify','/ˈrektɪfaɪ/','v. 纠正','Rectify the mistake.','write',1),
    ('substantiate','/səbˈstænʃieɪt/','v. 证实','Substantiate your claims.','write',0),
    ('undermine','/ˌʌndərˈmaɪn/','v. 削弱',"Don't undermine authority.",'write',1),
    ('acquiesce','/ˌækwiˈes/','v. 默认','She acquiesced to the plan.','read',0),
    ('broach','/broʊtʃ/','v. 提出','Broach a difficult topic.','read',1),
    ('concur','/kənˈkɜːr/','v. 同意','I concur with your view.','read',1),
    ('dispel','/dɪˈspel/','v. 驱散','Dispel the rumors.','write',1),
    ('emulate','/ˈemjuleɪt/','v. 仿效','Emulate his success.','read',1),
    ('fathom','/ˈfæðəm/','v. 理解','Hard to fathom why.','read',1),
    ('garner','/ˈɡɑːrnər/','v. 获得','Garner support.','read',1),
    ('harness','/ˈhɑːrnɪs/','v. 利用','Harness renewable energy.','write',1),
    ('incur','/ɪnˈkɜːr/','v. 招致','Incur a penalty.','write',1),
    ('lament','/ləˈment/','v. 痛惜','Lament the loss.','read',0),
    ('nurture','/ˈnɜːrtʃər/','v. 养育','Nurture talent.','write',1),
    ('obscure','/əbˈskjʊr/','v. 使模糊','The mist obscured the view.','write',1),
    ('persevere','/ˌpɜːrsəˈvɪr/','v. 坚持不懈','Persevere in your efforts.','write',1),
    ('quell','/kwel/','v. 平息','Quell the unrest.','read',0),
    ('reiterate','/riˈɪtəreɪt/','v. 重申','Reiterate the point.','write',1),
    ('stipulate','/ˈstɪpjuleɪt/','v. 规定','The contract stipulates that.','write',0),
  ];

  // 12成就（需求#8.2）：(id, title, desc, icon, xpReward)
  static const List<(String,String,String,String,int)> kAchievements12 = [
    ('first_study','🌱 初出茅庐','注册首日完成学习','first_study',50),
    ('word_100','📚 首杀百词','累计学习100个单词','word_100',100),
    ('streak_7','🔥 七日连击','连续打卡7天','streak_7',100),
    ('song_first','🎤 歌神降临','在歌房完成第一首歌曲练唱','song_first',80),
    ('file_first','📁 文件解析大师','成功解析第一个文件','file_first',60),
    ('perfect_dungeon','🎯 完美副本','单日三关全部S级完成','perfect_dungeon',200),
    ('streak_30','🐉 屠龙勇士','连续打卡30天','streak_30',500),
    ('word_1000','🧠 词汇王者','累计掌握1000个单词','word_1000',500),
    ('xh_10_push','⭐ 星回的认可','收到沈星回的第10条主动推送','xh_10_push',120),
    ('xh_reply_3','💫 心有灵犀','连续3天在沈星回推送后5分钟内回复','xh_reply_3',120),
    ('xh_100_rounds','💬 无尽对话','与沈星回累计聊天超过100轮','xh_100_rounds',150),
    ('intimacy_lv5','🔗 羁绊初生','亲密度等级达到Lv.5','intimacy_lv5',180),
  ];

  // 亲密度7个特殊解锁：(level, name, desc)
  static const List<(int,String,String)> kIntimacyUnlocks7 = [
    (1,'初识','他会用"你"称呼，语气客气克制'),
    (5,'指尖相触','解锁「牵手」部位点击反应'),
    (10,'温暖拥抱','解锁「拥抱」长按互动'),
    (11,'专属昵称','开始叫你"倩"，主动关心学习和身体'),
    (15,'专属晚安','他会等你确认睡了才说最后一句'),
    (16,'依赖感','语气中流露不易察觉的牵挂'),
    (20,'菲罗斯星的秘密','解锁只对你说的往事'),
  ];

  // 玩家默认值
  static const Map<String,Object?> kDefaultPlayer = {
    'player_name':'倩','level':1,'current_xp':0,'max_xp':1000,
    'streak_days':0,'last_study_date':null,
    'power_vocab':0,'power_listening':0,'power_speaking':0,'power_reading':0,
  };

  // 星回设置默认值
  static const Map<String,Object?> kDefaultXHSettings = {
    'id':1,'is_enabled':1,'daily_push_limit':3,
    'do_not_disturb_start':1380,'do_not_disturb_end':420, // 23:00 - 07:00 (分钟数)
    'reminder_items':'[]',
    'current_identity':'日常闲居','current_mode':'默认恋人',
    'user_nickname':'倩','intimacy_value':0,'intimacy_level':1,
    'total_chat_rounds':0,'days_known':1,
  };
}
