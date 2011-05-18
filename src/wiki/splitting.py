#!/usr/bin/env python

ENGLISH = 'en'
URDU = 'ur'
HINDI = 'hi'
SPANISH = 'es'
GERMAN = 'de'
FRENCH = 'fr'
CZECH = 'cs'
ARABIC = 'ar'
CHINESE = 'zh'
KOREAN = 'ko'
JAPANESE = 'ja'
LANGUAGE_CHOICES = (
    (ENGLISH, 'English'),
    (URDU, 'Urdu'),
    (HINDI, 'Hindi'),
    (SPANISH, 'Spanish'),
    (GERMAN, 'German'),
    (FRENCH, 'French'),
    (CZECH, 'Czech'),
	(ARABIC, 'Arabic'),
	(CHINESE, 'Chinese'),
	(KOREAN, 'Korean'),
	(JAPANESE, 'Japanese'),
)

import sys
import re
import nltk.data

def determine_splitter(language):
    if language == 'ur':
        return urdu_split_sentences

    for desc_pair in LANGUAGE_CHOICES:
        if desc_pair[0] == language:
            tokenizer = 'tokenizers/punkt/%s.pickle' % (desc_pair[1].lower())
            break
    try:
        tokenizer = nltk.data.load(tokenizer)
        return tokenizer.tokenize
    except:
        raise AttributeError('%s not supported by sentence splitters' % (language))

def urdu_split_sentences(text):
    """
    This function is a python implementation of Danish Munir's
    perl urdu-segmenter.
    """
    DASH = u'\u06D4' # arabic full stop
    QUESTION = u'\u061F'
    ELLIPSIS = u'\u2026'
    BULLET = u'\u2022'
    CR = u'\u000D'
    SPACE = u'\u0020'
    FULL_STOP = u'\u002e'
    
    text = text.replace('\r','')
    text = text.replace('\n','\n\n')
    reg_bullet = u'\s*%s\s*' % BULLET
    text = re.sub(reg_bullet, '\n\n\n\n\n', text)
    
    text = text.replace('\t* +\t*$', ' ')
    
    reg_cr = u'[\n%s][ ]+[\n%s]' % (CR, CR)
    text = re.sub(reg_cr, '\n\n', text)
    
    reg_space = u'^[\t%s]+$' % SPACE
    text = re.sub(reg_space, '\n\n', text)
    
    text = text.replace('|','')
    #/(\n{2,}|!|\x{061f}|\x{06D4}|\x{2022}|\x{000d}|\s{2,}|\x{2026}|\x{002e})/
    # '\n{2,}|!|QUESTION|DASH    |BULLET  |CR      |\s{2,}|ELLIPSIS|FULL_STOP'
    regex = u'(\n{2,}|!|%s|%s|%s|%s|\s{2,}|%s|\%s)' % (QUESTION, DASH, BULLET, CR, ELLIPSIS, FULL_STOP)
    p = re.compile(regex)
    sentences = p.split(text)

    new_string = ''
    segment_id = 1
    follow_up_punctuation = re.compile('[\n%s%s]' % (CR, BULLET))
    i = 0
    new_sentences = []
    while i < len(sentences):
        sent = sentences[i]
        sent = sent.strip()  # remove whitespace
        if len(sent) < 1:    # skip empty lines
            i = i+2
            continue
        new_string = new_string + sent
        # check punctuation in following sentence
        # if not newline, CR or BULLET, print it
        next_sent = sentences[i+1]
        if not follow_up_punctuation.match(next_sent):
            new_string = new_string + next_sent
        new_sentences.append(new_string + '\n')
        segment_id = segment_id + 1
        i = i + 2
    return new_sentences
