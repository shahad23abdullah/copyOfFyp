import numpy as np
import tensorflow as tf
import librosa
import pandas as pd
import pickle 
from tensorflow.image import resize # type: ignore
import subprocess
import soundfile as sf
import numpy as np
import librosa
from scipy.io.wavfile import write
import tqdm
import soundfile as sf



with open('trained_model.pkl', 'rb') as file:
    loaded_model = pickle.load(file)

def frame_audio(audio_array: np.ndarray,sample_rate=17000 , window_size_s: float = 5.0, hop_size_s: float = 5.0) -> np.ndarray:
    if window_size_s is None or window_size_s < 0:
        return audio_array[np.newaxis, :]
    frame_length = int(window_size_s * sample_rate)
    hop_length = int(hop_size_s * sample_rate)
    framed_audio = tf.signal.frame(audio_array, frame_length, hop_length, pad_end=True)
    return framed_audio

def extract_audio_features(segment, sr):
    chroma_stft = np.mean(librosa.feature.chroma_stft(y=segment, sr=sr))
    rms = np.mean(librosa.feature.rms(y=segment))
    spectral_centroid = np.mean(librosa.feature.spectral_centroid(y=segment, sr=sr)[0])
    spectral_bandwidth = np.mean(librosa.feature.spectral_bandwidth(y=segment, sr=sr)[0])
    rolloff = np.mean(librosa.feature.spectral_rolloff(y=segment, sr=sr)[0])
    zero_crossing_rate = np.mean(librosa.feature.zero_crossing_rate(y=segment)[0])
    mfccs = librosa.feature.mfcc(y=segment, sr=sr, n_mfcc=20)

    features = {
        'chroma_stft': chroma_stft,
        'rms': rms,
        'spectral_centroid': spectral_centroid,
        'spectral_bandwidth': spectral_bandwidth,
        'rolloff': rolloff,
        'zero_crossing_rate': zero_crossing_rate
    }

    for i in range(1, 21):
        features[f'mfcc{i}'] = np.mean(mfccs[i-1])
    return features

def calculate_threshold_from_audio(audio, factor=2):
    # Calculate Root Mean Square (RMS) of the audio
    rms = np.sqrt(np.mean(np.square(audio)))
    
    # Calculate threshold as a factor of RMS
    threshold = rms * factor
    
    return threshold  
    
def remove_noise_envelope(audio, rate, threshold):
    # Calculate the envelope mask
    audio_abs = np.abs(audio)
    window_size = int(rate /20)  # Calculate the window size based on the sample rate
    audio_mean = pd.Series(audio_abs).rolling(window=window_size, min_periods=1, center=True).max()
    
    # Create the mask by comparing with the threshold
    mask = audio_mean > threshold
    
    # Apply the envelope mask to remove noise
    denoised_audio = np.where(mask, audio, 0)
    
    return denoised_audio

def preprocessAudio():
    AudioFromUser = r'C:\Users\shaha\OneDrive\Desktop\FYP\audio.wav'
    x, sr = librosa.load(AudioFromUser)
    framed_audio =frame_audio(x, sr ,window_size_s=5.0, hop_size_s=5.0 )
    df = pd.DataFrame({'Segment': [tf.reshape(frame, [-1]).numpy() for frame in framed_audio]})
    df['Features'] = df['Segment'].apply(lambda segment: extract_audio_features(segment, sr))
    df = pd.concat([df.drop(['Features'], axis=1), df['Features'].apply(pd.Series)], axis=1)
    df = df.drop(['Segment'], axis=1)
    df.to_csv('framed_audio_segments_with_features3.csv', index=False)

def detect_silence(audio_path, time):
    ffmpeg_path = 'C:/Path_program/ffmpeg.exe'
    command = f"{ffmpeg_path} -i {audio_path} -af silencedetect=n=-23dB:d={time} -f null -"
    out = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    stdout, stderr = out.communicate()
    s = stdout.decode("utf-8")
    k = s.split('[silencedetect @')

    if len(k) == 1:
        return None

    start, end = [], []
    for i in range(1, len(k)):
        x = k[i].split(']')[1]
        if i % 2 == 0:
            x = x.split('|')[0]
            x = x.split(':')[1].strip()
            end.append(float(x))
        else:
            x = x.split(':')[1]
            x = x.split('size')[0]
            x = x.replace('\r', '')
            x = x.replace('\n', '').strip()
            start.append(float(x))

    return list(zip(start, end))

def remove_silence(audio, sil,rate, out_path):
    sil_updated = [(i[0], i[1]) for i in sil]

    non_sil = []
    tmp = 0
    ed = len(audio) / rate
    for i in range(len(sil_updated)):
        non_sil.append((tmp, sil_updated[i][0]))
        tmp = sil_updated[i][1]
    if sil_updated[-1][1] < ed:
        non_sil.append((sil_updated[-1][1], ed))
    if non_sil[0][0] == non_sil[0][1]:
        del non_sil[0]

    # Cut the audio
    print('Slicing started...')
    ans = []
    for start, end in tqdm.tqdm(non_sil):
        ans.extend(audio[int(start * rate):int(end * rate)])
    write(out_path, rate, np.array(ans))
    return non_sil

def prediction():
    test_df = pd.read_csv('framed_audio_segments_with_features3.csv')
    X_test = np.array(test_df.iloc[:, :])  # Features (exclude 'LABEL' column)
    X_test_cnn = X_test.reshape(X_test.shape[0], X_test.shape[1], 1)
    X_test_cnn_reshaped = np.expand_dims(X_test_cnn, axis=-1)
    X_test_cnn_reshaped_resized = resize(X_test_cnn_reshaped, [178, 257])
    predictions = loaded_model.predict(X_test_cnn_reshaped_resized)
    predictionForAudio = [1 if round(float(prediction),1) > 0.3 else 0 for prediction in predictions]
    predicted_labels = np.array(predictionForAudio)
    return predicted_labels
    
    
def calculatePercent(labels):
    count_label_1 = np.sum(labels == 1)
    total_labels = len(labels)
    percentage_label_1 = (count_label_1 / total_labels) * 100
    return percentage_label_1

def percen():
   preprocessAudio()
   labels = prediction()
   percent = calculatePercent(labels)
   return str(percent)



def realTime():
    preprocessAudio()
    